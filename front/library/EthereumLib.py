from web3 import Web3, eth

real_server = 'https://eth-goerli.g.alchemy.com/v2/h2EvZz6TPtgyKXoinc4mpVQLeunHd2LI'
debug_server = 'http://127.0.0.1:8545/'
test_privatekey = "e46745b0ff6b51ffeec10ffa57db3c95cf606a41089e9cbddc39eb5a07853a1e"

debug_privatekey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

def call_function(contract, function, parameter, values):
    result = contract.functions[function](parameter).transact(values)
    return result

def get_user_balance(web3, user_account):
    return web3.eth.get_balance(user_account)

def connect_to_network(debug_mode=False):
    if debug_mode == False:
        provider = Web3.HTTPProvider(real_server)
    else:
        provider = Web3.HTTPProvider(debug_server)
    return [Web3(provider), provider]

def login(web3, user_privateKey, debug_mode=False):
    if debug_mode == True:
        return web3.eth.accounts[0]
    return web3.eth.account.privateKeyToAccount(user_privateKey)

if __name__ == '__main__':
    DEBUG = False
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
    print(my_account.address)
    print(w.eth.get_balance(my_account.address))