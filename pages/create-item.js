import { useState } from 'react'
import { ethers } from 'ethers'
import { create as ipfsHttpClient } from 'ipfs-http-client'
import { useRouter } from 'next/router'
import Web3Modal from 'web3modal'

const client = ipfsHttpClient('https://ipfs.infura.io:5001/api/v0')

import {
  nftaddress, nftmarketaddress
} from '../config'

import NFT from '../artifacts/contracts/NFT.sol/NFT.json'
import Market from '../artifacts/contracts/Market.sol/NFTMarket.json'

export default function CreateItem() {
    const [fileUrl,setFileUrl] = useState(null)
    const [formInput, setFormInput] = useState({price:"", name: "", description: ""})
    const router = useRouter()

    async function onChange(e){
        const ifle = e.target.files[0]
        try {
            const added = await client.add(
                file,{
                    progress: (prog)=> console.log(`received: ${prog}`)
                }
            )
            const url = `https://ipfs.infure.io/ipfs/${added.path}`
        } catch (error) {
            console.log('Error: ', error)
        }
    }

    async function createMarket() {
        const {name,description,price} = formInput
        if(!name || !description || !price || !fileUrl) return

        const data = JSON.stringify({
            name,description, image:fileUrl
        })
        try {
            const added = await client.add(data)
            const url = `https://ipfs.infure.io/ipfs/${added.path}`
            createSale(url)
        } catch (error) {
            console.log("Error: ", error)
        }
    }

    async function createSale(url){
        const web3Modal = new Web3Modal()
        const connection = await web3Modal.connect()
        const provider = new ethers.providers.Web3Provider(connection)
        const signer = provider.getSigner()

        let contract = new ethers.Contract(nftaddress,NFT.abi, signer)
        let transaction = await contract.createToken(url)
        let tx = await transaction.wait()
        let event = tx.events[0]
        let value = event.args[2]
        let tokenId = value.toNumber()
        const price = ethers.utils.parseUnits(formInput.price, 'ether')
    
        /* then list the item for sale on the marketplace */
        contract = new ethers.Contract(nftmarketaddress, Market.abi, signer)
        let listingPrice = await contract.getListingPrice()
        listingPrice = listingPrice.toString()
    
        transaction = await contract.createMarketItem(nftaddress, tokenId, price, { value: listingPrice })
        await transaction.wait()
        router.push('/')
    }
    return (
        <div>
            <div>
                <input placeholder="Asset Name" onChange={e=>setFormInput({...formInput,name:e.target.value})}/>
                <textarea placeholder="Asset Description" onChange={e=>setFormInput({...formInput, description:e.target.value})}/>
                <input placeholder="Asset Price in ETH" onChange={e=>setFormInput({...formInput, price:e.target.value})}/>
                <input type="file" name="Asset" onChange={onChange}/>
                {
                    fileUrl && (<img width="350" src={fileUrl}/>)
                }
                <button onClick={createMarket}>Create Digital Asset</button>
            </div>
        </div>
    )
}