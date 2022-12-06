from flask import Flask, request, render_template, redirect, url_for, abort

app =Flask(__name__)

@app.route('/home')
def home():
    return render_template("home.html")

@app.route('/')
def hello():
    return 'Hello, World!'

@app.route('/login')
def login():
    return render_template("login.html")

@app.route('/login/walletPopup')
def walletPopup():
    return render_template("walletPopup.html")

@app.route('/home/patentApp')
def patentApp():
    return render_template("patentApp.html")

@app.route('/home/patentApp/cancelPopup')
def cancelPopup():
    return render_template("cancelPopup.html")

@app.route('/home/patentManagement')
def patentManagement():
    return render_template("patentManagement.html")
    
@app.route('/home/patentManagement/PatentManView')
def PatentManView():
    return render_template("PatentManView.html")

@app.route('/home/auction')
def auction():
    return render_template("auction.html")

@app.route('/home/auction/auctionSell')
def auctionSell():
    return render_template("auctionSell.html")

@app.route('/home/auction/auctionView')
def auctionView():
    return render_template("auctionView.html")

@app.route('/home/setting')
def setting():
    return render_template("setting.html")

@app.route('/adminHome')
def adminHome():
    return render_template("adminHome.html")

@app.route('/adminHome/adminExamination')
def adminExamination():
    return render_template("adminExamination.html")

@app.route('/adminHome/adminExamView')
def adminExamView():
    return render_template("adminExamView.html")
    


if __name__ == '__main__':
    app.run(debug=True)