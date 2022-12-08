import sys, os
from flask import Flask, request, render_template, redirect, url_for, abort, session

import pickle
from functools import wraps

sys.path.insert(1, os.getcwd() + "/library/")
import EthereumLib

app =Flask(__name__)
app.secret_key = "MY_SECRET_KEY"

# Global Variable secation
provider = None
web3 = None

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

# Routing section
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

@app.route('/login/walletPopup')
def walletPopup():
    return render_template("walletPopup.html")

@app.route('/home/patentApp')
def patentApp():
    return render_template("patentApp.html")

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
        print(request.form.get('private_key'))
        my_account = EthereumLib.login(web3, request.form.get('private_key'))
        my_balance = EthereumLib.get_user_balance(web3, my_account.address)
        if my_balance > 0:
            session['loginSession'] = pickle.dumps(my_account)
            #print(session['loginSession'])
            return redirect(url_for('home'))
        else:
            return redirect(url_for('login'))
    else:
        return abort(403)


# Not routing section
def initialize_by_startup():
    global web3
    global provider
    try:
        [web3, provider] = EthereumLib.connect_to_network()
    except Exception as e:
        return False
    return True

if __name__ == '__main__':
    assert initialize_by_startup() == True, "Initialize Failed"
    app.run(debug=True)