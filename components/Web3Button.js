import {ethers} from "ethers"
import Web3Modal from 'web3modal';
const providerOptions = {

}
const Web3Button = () => {

    const handleConnect = async () => {
        console.log("helllo")
    const web3Modal = new Web3Modal()
    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)    
    const signer = provider.getSigner()
    
    }

    return (
        <button onClick={handleConnect} className="rounded-md bg-pink-200 p-2 hover:bg-pink-400">Connect to Wallet</button>
    )
}
export default Web3Button;