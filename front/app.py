#!/usr/bin/python3
import sys, os, json
from flask import Flask, request, render_template, redirect, url_for, abort, session, render_template_string

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
MarketPlaceAddress = '0x9f1ac54BEF0DD2f6f3462EA0fa94fC62300d3a8e'

NFTImplementationABI = json.loads(open("./metadata/NFTImplementation.json", 'rb').read())['abi']
MarketPlaceABI = json.loads(open("./metadata/MarketPlace.json", 'rb').read())['abi']

NFTImplementation = None
MarketPlace = None

DEBUG = True

ERROR_TEMPLATE = """
<script>
alert('$MESSAGE');
location.href='/home';
</script>
"""

def getUserTokens():
    my_account = pickle.loads(session['loginSession'])
    values = {
        'from': my_account.address
    }
    tokens = EthereumLib.call_function_view_noArg(NFTImplementation, 'getUserTokenList', values)
    return tokens

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

# 이건 사용할 필요 없음
@app.route('/home/patentApp/registerPopup')
def registerPopup():
    return render_template("registerPopup.html")

@app.route('/home/patentApp/cancelPopup')
def cancelPopup():
    return render_template("cancelPopup.html")

@app.route('/home/patentManagement')
def patentManagement(tokens=None):
    return render_template("patentManagement.html", tokens=tokens)
    
@app.route('/home/patentManagement/PatentManView')
def patentManView():
    return render_template("patentManView.html")

@app.route('/home/auction')
def auction():
    # Get opened auction list
    opened_markets = []
    my_account = pickle.loads(session['loginSession'])
    for i in range(0, 5):
        result = MarketPlace.functions.checkMarketisOpen(i).call(
            {'from': my_account.address}
        )
        if result == True:
            opened_markets.append([i, f"MarketID {i}"])
    return render_template("auction.html", len=len(opened_markets), marketInfo=opened_markets)

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
            'unique_id': int(request.form.get('field')),
            'title': request.form.get('title'),
            'contentURI': request.form.get('contentURI')
        }
        EthereumLib.call_function(NFTImplementation, 'mint', parameters, values)
    else:
        return abort(403)
    return render_template('patentManagement.html', tokens=getUserTokens())

# 지금은 GET을 허용함, 디버깅 용도로 사용할 예정이라서
# 이후에 Cancel 페이지가 수정되고 나면 업데이트 예정


@app.route('/api/burn', methods=['GET', 'POST'])
@session_check
def handle_burn():
    # Just request and put into queue
    if request.method=="GET":
        my_account = pickle.loads(session['loginSession'])
        try:
            NFTImplementation.functions.requestBurning(int(request.args['tokenID'])).transact(
                {'from': my_account.address}
            )
        except Exception as e:
            return render_template_string(
                "<script>alert(\"아직 해당 토큰을 제거할 수 없습니다.\");location.href=\"/home\";</script>"
            )
    elif request.method=="POST":
        return abort(403)
    else:
        return abort(403)
    return redirect(url_for('patentApp'))

# 이거도 일시적으로 GET 허용해줌
# 이유는 Form이 Submit 버튼이 안나옴.. CSS문제인 것 같음
@app.route('/api/auction', methods=['GET', 'POST'])
@session_check
def handle_auction():
    
    return render_template('auctionSell.html', token=searched_token)

# 일단 전부다 GET, POST 허용해서 GET 버전으로 작성해둘테니까 POST 동작 가능하게 프론트 수정해주세요
# 지금 프론트 기능 동작에 문제가 많네요
@app.route('/api/startAuction', methods=['GET', 'POST'])
@session_check
def handle_startAuction():
    my_account = pickle.loads(session['loginSession'])
    if request.method == "GET":
        marketID = int(request.args.get('marketID'), 10)
        tokenID = int(request.args.get('tokenID'), 10)
        startCost = int(request.args.get('startCost'), 10)

        try:
            NFTImplementation.functions.startAuction(marketID, tokenID, startCost).transact(
                {'from': my_account.address}
            )
        except Exception as e:
            error_msg = "해당 토큰은 이미 경매에 부쳐졌습니다."
            return render_template_string(ERROR_TEMPLATE.replace("$MESSAGE", error_msg))
    elif request.method == "POST":
        return
    else:
        return abort(403)
    return redirect(url_for('auction'))

@app.route('/api/endAuction', methods=['GET', 'POST'])
@session_check
def handle_endAuction():
    my_account = pickle.loads(session['loginSession'])
    if request.method == "GET":
        marketID = int(request.args.get('marketID'), 10)
        tokenID = int(request.args.get('tokenID'), 10)
        try:
            NFTImplementation.functions.endAuction(marketID, tokenID).transact(
                {'from': my_account.address}
            )
        except Exception as e:
            error_msg = "해당 경매는 아직 종료할 수 없습니다."
            return render_template_string(ERROR_TEMPLATE.replace("$MESSAGE", error_msg))
    elif request.method == "POST":
        return
    else:
        return abort(403)
    return redirect(url_for('auction'))

@app.route('/api/suggest', methods=['GET', 'POST'])
@session_check
def handle_auctionSuggest():
    my_account = pickle.loads(session['loginSession'])
    if request.method == "GET":
        marketID = int(request.args.get('marketID'), 10)
        tokenID = int(request.args.get('tokenID'), 10)
        suggestCost = int(request.args.get('suggestCost'), 10)
        try:
            NFTImplementation.functions.suggestCost(marketID, tokenID, suggestCost).transact(
                {'from': my_account.address}
            )
        except Exception as e:
            error_msg = "제시가를 제시하는데에 실패하였습니다."
            return render_template_string(ERROR_TEMPLATE.replace("$MESSAGE", error_msg))
    elif request.method == "POST":
        return
    else:
        return abort(403)
    return redirect(url_for('auction'))

@app.route('/api/selling', methods=['GET', 'POST'])
@session_check
def handle_auctionSelling():
    my_account = pickle.loads(session['loginSession'])
    if request.method == "GET":
        marketID = int(request.args.get('marketID'), 10)
        tokenID = int(request.args.get('tokenID'), 10)
        minPrice = int(request.args.get('minPrice'), 10)
        salePrice = int(request.args.get('salePrice'), 10)

        NFTImplementation.functions.applyItem(marketID, tokenID, minPrice).transact(
            {'from': my_account.address}
        )
    elif request.method == "POST":
        return
    else:
        return abort(403)
    return redirect(url_for('home'))

@app.route('/api/changeItemCost', methods=['GET', 'POST'])
@session_check
def handle_changeItemCost():
    my_account = pickle.loads(session['loginSession'])
    if request.method == "GET":
        marketID = int(request.args.get('marketID'), 10)
        tokenID = int(request.args.get('tokenID'), 10)
        newCost = int(request.args.get('newCost'), 10)

        try:
            NFTImplementation.functions.changeItemCost(marketID, tokenID, newCost).transact(
                {'from': my_account.address}
            )
        except Exception as e:
            error_msg = "가격을 변경하는데에 실패하였습니다."
            return render_template_string(ERROR_TEMPLATE.replace("$MESSAGE", error_msg))
    elif request.method == "POST":
        return
    else:
        return abort(403)
    return redirect(url_for('home'))

@app.route('/api/deleteItem', methods=['GET', 'POST'])
@session_check
def handle_deleteItem():
    my_account = pickle.loads(session['loginSession'])
    if request.method == "GET":
        marketID = int(request.args.get('marketID'), 10)
        tokenID = int(request.args.get('tokenID'), 10)

        try:
            NFTImplementation.functions.deleteItem(marketID, tokenID).transact(
                {'from': my_account.address}
            )
        except Exception as e:
            error_msg = "해당 아이템을 삭제하는데에 실패했습니다."
            return render_template_string(ERROR_TEMPLATE.replace("$MESSAGE", error_msg))
    elif request.method == "POST":
        return
    else:
        return abort(403)
    return redirect(url_for('home'))

@app.route('/api/purchaseItem', methods=['GET', 'POST'])
@session_check
def handle_purchaseItem():
    my_account = pickle.loads(session['loginSession'])
    if request.method == "GET":
        marketID = int(request.args.get('marketID'), 10)
        tokenID = int(request.args.get('tokenID'), 10)
        try:
            NFTImplementation.functions.purchaseItem(marketID, tokenID).transact(
                {'from': my_account.address}
            )
        except Exception as e:
            error_msg = "해당 아이템을 구매하는데에 실패하였습니다."
            return render_template_string(ERROR_TEMPLATE.replace("$MESSAGE", error_msg))
    elif request.method == "POST":
        return
    else:
        return abort(403)
    return redirect(url_for('home'))

# Not routing section
def initialize_by_startup():
    global web3
    global provider
    global NFTImplementation
    global MarketPlace
    try:
        [web3, provider] = EthereumLib.connect_to_network(debug_mode=True)
        NFTImplementation = web3.eth.contract(address=NFTImplementationAddress, abi=NFTImplementationABI)
        MarketPlace = web3.eth.contract(address=MarketPlaceAddress, abi=MarketPlaceABI)
        print(f"[*] NFTImplementation Contract : {NFTImplementation}")
        print(f"[*] MarketPlace Contract : {MarketPlace}")
    except Exception as e:
        return False
    return True

if __name__ == '__main__':
    assert initialize_by_startup() == True, "Initialize Failed"
    app.run(debug=True)
