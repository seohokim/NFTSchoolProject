import time
import random
import json

from web3 import Web3
from apscheduler.schedulers.background import BackgroundScheduler

# Read configuration file
with open('config.json') as f:
    config = json.load(f)

sched = BackgroundScheduler()
web3 = Web3(Web3.HTTPProvider(config['alchemy']['rpc_url']))
#@sched.scheduled_job('interval', seconds=60*30, id='itemGenerator')
#def schedule_item():
    # Make items randomly

def balanceTest():
    address = config['alchemy']['account']
    balances = web3.fromWei(web3.eth.get_balance(address), "ether")
    print(balances)
