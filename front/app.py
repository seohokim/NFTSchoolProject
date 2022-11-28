from flask import Flask, request, render_template, redirect, url_for, abort

app =Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World!'

@app.route('/login')
def login():
    return render_template("login.html")

@app.route('/userHome')
def userHome():
    return render_template("userHome.html")
    
@app.route('/userHome/myinfo')
def myinfo():
    return render_template("myInfo.html")

@app.route('/userHome/myTokenManage')
def myTokenManage():
    return render_template("myTokenManage.html")

@app.route('/userHome/exchangeHome')
def exchangeHome():
    return render_template("exchangeHome.html")

@app.route('/userHome/myTokenManage/burnRequest')
def burnRequest():
    return render_template("burRequest.html")

@app.route('/userHome/myTokenManage/recoverRequest')
def recoverRequest():
    return render_template("recoverRequest.html")

@app.route('/userHome/exchangeHome/auction')
def auction():
    return render_template("auction.html")

@app.route('/userHome/exchangeHome/market')
def market():
    return render_template("market.html")

@app.route('/userHome/exchangeHome/market/nowOnAuction')
def nowOnAuctionList():
    return render_template("nowOnAuctionList.html")

@app.route('/userHome/exchangeHome/market/myAuctionStatus')
def myAuctionStatus():
    return render_template("myAuctionStatus.html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")
    
# @app.route('/')
# def ():
#     return render_template(".html")

# @app.route('/')
# def ():
#     return render_template(".html")

if __name__ == '__main__':
    app.run(debug=True)