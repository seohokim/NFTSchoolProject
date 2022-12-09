import json
from web3 import Web3, eth

def get_user_balance(user_account):
    return w.eth.get_balance(user_account)

def function_call(contract, function, parameter, values):
    result = contract.functions[function](parameter).transact(values)
    return result

def test_contract_call():
    one_ether = 10 ** 18
    with open("./metadata/NFTImplementation.json", 'rb') as f:
        json_data = f.read()
    json_object = json.loads(json_data)
    NFTImplementationAddress = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512';
    NFTImplementation = w.eth.contract(address=NFTImplementationAddress, abi=json_object['abi'])
    function_call(NFTImplementation, 'mint', {'unique_id': 0x2}, {'from': my_account, 'value': Web3.toWei(0.001, 'ether')})
    # NFTImplementation.functions.mint({'unique_id': 0x1}).transact({"from": my_account, "value": Web3.toWei(0.001, 'ether')})

DEBUG = True
if DEBUG == False:
    ALCHEMY_ADDRESS = 'https://eth-goerli.g.alchemy.com/v2/h2EvZz6TPtgyKXoinc4mpVQLeunHd2LI'
else:
    ALCHEMY_ADDRESS = 'http://127.0.0.1:8545/'

provider = Web3.HTTPProvider(ALCHEMY_ADDRESS)
w = Web3(provider)

# Account Setting
if DEBUG == False:
    my_account = '0x0B6DFAE82d3a5Aeff21f01DE1b0BB60530A57Cb3'
    my_account = w.eth.account.privateKeyToAccount("e46745b0ff6b51ffeec10ffa57db3c95cf606a41089e9cbddc39eb5a07853a1e")
else:
    my_account = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'   # The first account of hardhat

test_contract_call()