

import Web3 from "web3"
import { newKitFromWeb3 } from "@celo/contractkit"
import BigNumber from "bignumber.js"
import marketplaceAbi from "../contract/marketplace.abi.json"
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18
const MPContractAddress = "0x6fE8754e67095eD9Fda0463f7375B4C8CE926866"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

let kit
let contract
let aesthetics = [];

const connectCeloWallet = async function () {
  if (window.celo) {
    notification("⚠️ Please approve this DApp to use it.")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}

const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}

const getProducts = async function() {
  const _aestheticLength = await contract.methods.aestheticLength().call()
  const _aestheticArr = []
  for (let i = 0; i < _aestheticLength; i++) {
  let _aesthetic = new Promise(async (resolve, reject) => {
    let p = await contract.methods.readAesthetic(i).call()
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        location: p[4],
        price: new BigNumber(p[5]),
        sold: p[6],
      })
    })
    _aestheticArr.push(_aesthetic)
  }
  aesthetics = await Promise.all(_aestheticArr)
  renderProducts()
}



function renderProducts() {

  let marketplace = $("#marketplace");
  marketplace.empty();

  if (aesthetics) {
    for (let i = 0; i < aesthetics.length; i++) {
      if (aesthetics[i]["name"].length) {
        marketplace.append(
          `
          <div class="col-md-4">

            <div class="card mb-4">

              <img class="card-img-top" src="${aesthetics[i].image}" alt="..." style="height : 150px;">
              <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
                ${aesthetics[i].sold} Sold
              </div>

              <div class="card-body text-left p-3 position-relative">

                <div class="translate-middle-y position-absolute top-0 end-0"  id="${aesthetics[i].index}">
                ${identiconTemplate(aesthetics[i].owner)}
                </div>

                <p class="card-title  fw-bold mt-2 text-uppercase">${aesthetics[i].name}</p>
                <p class="mt-2 text-left fs-6">
                  ${new BigNumber(aesthetics[i].price).shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
                </p>
                <p class="mt-2 text-left fs-6">
                  ${aesthetics[i].description}
                </p>
                <i class="bi bi-geo-alt-fill"></i>
                <span class="mt-2 text-left fs-6">
                  ${aesthetics[i].location}
                </span>

                <div class="d-grid gap-2">
              
                <div class="d-flex justify-content-between">
                    <a class="btn btn-lg btn-dark deleteBtn fs-6 p-3 me-2" id=${aesthetics[i].index} style="background-color: #f3d7b3; border: none; color: black;">Delete Aesthete</a>
                    <a class="btn btn-lg btn-dark editBtn fs-6 p-3 me-2" id=${aesthetics[i].index} style="background-color: #f3d7b3; border: none; color: black;">Edit Price</a>
                </div>

                <a class="btn btn-lg btn-dark buyBtn fs-6 p-3" id=${aesthetics[i].index} style="background-color: #7d5a50; border: none;">
                Buy for ${aesthetics[i].price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
            </a> 
            </div>
                
              </div>
            </div>
          </div>

          `
        )
      }
    }
  }

}

function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}

function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}

window.addEventListener("load", async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getProducts()
  notificationOff()
});


document
  .querySelector("#listAestheticBtn")
  .addEventListener("click", async (e) => {

    const params = [
      document.getElementById("aestheticName").value,
      document.getElementById("aestheticImgUrl").value,
      document.getElementById("aestheticDescription").value,
      document.getElementById("aestheticLocation").value,
      new BigNumber(document.getElementById("price").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString()
    ]
    notification(`⌛ Adding "${params[0]}"...`)
    try {
      await contract.methods
        .listAesthetic(...params) 
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`🎉 You successfully added "${params[0]}".`)
    getProducts()
  })

// implements the buy functionalities of a listed aesthetic
document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("buyBtn")) {
    const index = e.target.id
    notification("⌛ Waiting for payment approval...")
    try {
      await approve(aesthetics[index].price)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`⌛ Awaiting payment for "${aesthetics[index].name}"...`)
    try {
      await contract.methods
        .buyCamera(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully bought "${aesthetics[index].name}".`)
      getProducts()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }

    notificationOff()
  }
})  

// implements the delete functionalities of a listed aesthetic
document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("deleteBtn")) {

    // declaring variables for the smartcontract parameters
    const index = e.target.id
    console.log(index);

    notification(`⌛ Deleting "${aesthetics[index].name}"...`)
    try {
      // const result = 
      await contract.methods
        .deleteAesthetic(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully deleted "${aesthetics[index].name}".`)
      getProducts()

    } catch (error) {
      notification(`⚠️ ${error}.`)
    }

    notificationOff()
 
  }
})

document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("editBtn")) {

    // open modal with jquery
    jQuery('#addModalForEdit').modal('show'); 

    // store id in the local storage
    localStorage.setItem("indexLS", e.target.id)
  

  }
})

document
  .querySelector("#editAestheticBtn")
  .addEventListener("click", async (e) => {

    let price = new BigNumber(document.getElementById("newPrice").value).shiftedBy(ERC20_DECIMALS)
      .toString()

    // Get the index from the local storage
    const index = localStorage.getItem("indexLS")

    notification(`⌛ Editing "${aesthetics[index].name}"...`)
    try {

      await contract.methods
        .editPrice(index, price)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully edited "${aesthetics[index].name}".`)
      getProducts()

    } catch (error) {
      notification(`⚠️ ${error}.`)
    }

    notificationOff()

  })

