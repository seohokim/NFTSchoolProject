import sys, os, json
from flask import Flask, request, render_template, redirect, url_for, abort, session

import pickle
from functools import wraps

sys.path.insert(1, os.getcwd() + "/library/")
import EthereumLib

from web3 import Web3

app =Flask(__name__)
app.secret_key = "MY_SECRET_KEY"

# Global Variable secation
provider = None
web3 = None
NFTImplementationAddress = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'
NFTImplementationABI = json.loads(open("./metadata/NFTImplementation.json", 'rb').read())['abi']
NFTImplementation = None

DEBUG = True

# Decorator section
def session_check(a_function):              # Only for login session
    @wraps(a_function)
    def decorated_func(*args, **kwargs):
        #print(session.get('loginSession'))
        if session.get('loginSession'):
            return a_function(*args, **kwargs)
        else:
            return redirect(url_for('login'))
    return decorated_func

# Routing section (Basic Login/Logout Logics)
@app.route('/')
@app.route('/index')                # / is /index default
@session_check
def index():
    return redirect(url_for('home'))

@app.route('/home')
@session_check
def home():
    return render_template("home.html")

@app.route('/login')
def login():
    return render_template("loginForm.html")

@app.route('/logout')
@session_check
def logout():
    session.pop('loginSession', None)
    return redirect(url_for('login'))

# No need walletPopup now
@app.route('/login/walletPopup')
def walletPopup():
    return render_template("walletPopup.html")

# Minting, Burning Routing Section

@app.route('/home/patentApp')
def patentApp():
    # Read all tokens of user
    my_account = pickle.loads(session['loginSession'])
    values = {
        'from': my_account.address
    }
    tokens = EthereumLib.call_function_view_noArg(NFTImplementation, 'getUserTokenList', values)
    print("Tokens : " + str(tokens))
    # List tokens into Cancel Application tab
    return render_template("patentApp.html", len = len(tokens), tokens=tokens)

@app.route('/home/patentApp/registerPopup')
def registerPopup():
    return render_template("registerPopup.html")

@app.route('/home/patentApp/cancelPopup')
def cancelPopup():
    return render_template("cancelPopup.html")

@app.route('/home/patentManagement')
def patentManagement():
    return render_template("patentManagement.html")
    
@app.route('/home/patentManagement/PatentManView')
def patentManView():
    return render_template("patentManView.html")

    

@app.route('/home/auction')
def auction():
    return render_template("auction.html")

@app.route('/home/auction/auctionSell')
def auctionSell():
    return render_template("auctionSell.html")

@app.route('/home/auction/auctionView')
def auctionView():
    return render_template("auctionView.html")

@app.route('/home/auction/auctionView/buyNowPopup')
def buyNowPopup():
    return render_template("buyNowPopup.html")



@app.route('/adminHome')
def adminHome():
    return render_template("adminHome.html")

@app.route('/adminHome/banPopup')
def banPopup():
    return render_template("banPopup.html")

@app.route('/adminHome/banPopup/notBannedPopup')
def notBannedPopup():
    return render_template("notBannedPopup.html")

@app.route('/adminHome/unbanPopup')
def unbanPopup():
    return render_template("unbanPopup.html")

@app.route('/adminHome/unbanPopup/notUnbannedPopup')
def notUnbannedPopup():
    return render_template("notUnbannedPopup.html")



@app.route('/adminHome/burningPopup')
def burningPopup():
    return render_template("burningPopup.html")

@app.route('/adminHome/burningPopup/notBurnedPopup')
def notBurnedPopupp():
    return render_template("notBurnedPopup.html")

@app.route('/adminExamination')
def adminExamination():
    return render_template("adminExamination.html")

@app.route('/adminExamination/adminExamView')
def adminExamView():
    return render_template("adminExamView.html")
    
# API Section
@app.route('/api/login', methods=['POST'])
def handle_login():
    if web3 == None:
        return abort(403)
    if 'loginSession' in session:
        return redirect(url_for('home'))
    if request.method == 'POST':
        # Only allowed on POST
        #print(request.form.get('private_key'))
        private_key = request.form.get('private_key')
        if DEBUG == True:
            private_key = EthereumLib.debug_privatekey
        my_account = EthereumLib.login(web3, private_key)
        my_balance = EthereumLib.get_user_balance(web3, my_account.address)
        if my_balance > 0:
            session['loginSession'] = pickle.dumps(my_account)
            #print(session['loginSession'])
            return redirect(url_for('home'))
        else:
            return redirect(url_for('login'))
    else:
        return abort(403)

@app.route('/api/mint', methods=['POST'])
@session_check
def handle_mint():
    if request.method == "POST":
        my_account = pickle.loads(session['loginSession'])
        values = {
            'from': my_account.address,
            'value': Web3.toWei(0.001, 'ether')
        }
        parameters = {
            'unique_id': int(request.form.get('field'))
        }
        EthereumLib.call_function(NFTImplementation, 'mint', parameters, values)
    else:
        return abort(403)
    return redirect(url_for('patentApp'))

# Not routing section
def initialize_by_startup():
    global web3
    global provider
    global NFTImplementation
    try:
        [web3, provider] = EthereumLib.connect_to_network(debug_mode=True)
        NFTImplementation = web3.eth.contract(address=NFTImplementationAddress, abi=NFTImplementationABI)
        print(f"[*] NFTImplementation Contract : {NFTImplementation}")
    except Exception as e:
        return False
    return True

if __name__ == '__main__':
    assert initialize_by_startup() == True, "Initialize Failed"
    app.run(debug=True)