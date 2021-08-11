import Head from 'next/head'
import Image from 'next/image'
import styles from '../styles/Home.module.css'
import {ethers} from "ethers"
import axios from 'axios'
import Web3Modal from 'web3modal'
import {nftaddress, nftmarketaddress} from "../config"
import { useEffect, useState } from 'react'

import NFT from "../artifacts/contracts/NFT.sol"
import Market from "../artifacts/contracts/Market.sol"

export default function Home() {
  const [nfts, setNfts] = useState([])
  const [loadingState, setLoadingState] = useState('not-loaded')
  useEffect(()=> {
    loadNFTS()
  },[])

  async function loadNFTS() {
    const provider = new ethers.providers.JsonRpcProvider()
    const tokenContract = new ethers.Contract(nftaddress, NFT.abi, provider)
    const marketContract = new ethers.Contract(nftmarketaddress, Market.abi, provider)
    const data = await marketContract.fetchMarketItems()

    const items = await Promise.all(data.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      const meta = await axios.get(tokenUri)
      let price = ethers.utils.formatUnits(i.price.toString(), 'ether')
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        owner: i.owner,
        image: meta.data.image,
        name: meta.data.name,
        description: meta.data.description,
      }
      return item
    }))
    setNfts(items)
    setLoadingState('loaded') 

  }
  async function buyNft(nft) {
    /* needs the user to sign the transaction, so will use Web3Provider and sign it */
    const web3Modal = new Web3Modal()
    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)
    const signer = provider.getSigner()
    const contract = new ethers.Contract(nftmarketaddress, Market.abi, signer)

    /* user will be prompted to pay the asking proces to complete the transaction */
    const price = ethers.utils.parseUnits(nft.price.toString(), 'ether')   
    const transaction = await contract.createMarketSale(nftaddress, nft.tokenId, {
      value: price
    })
    await transaction.wait()
    loadNFTs()
  }
  if(loadingState === 'loaded' && !nfts.length) return (<h1>No items in marketplace</h1>)
  return (
    <div className="flex justify-center">
      <div className="px-4" style={{maxWidth: '1600px'}}>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4">
          {
            nfts.map((nft,i)=>(
              <div>
                <img src={nft.image}/>
                <div>
                    <p>{nft.name}</p>
                    <div>
                      <p>{nft.description}</p>
                    </div>
                  </div>
                  <div>
                      <p>{nft.price} ETH</p>
                      <button>Buy</button>
                    </div>
                </div>
            ))
          }
        </div>
      </div>
    </div>
  )
}
