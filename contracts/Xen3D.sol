/**
 *Submitted for verification at Etherscan.io on 2018-04-10
 */

pragma solidity ^0.4.20;

interface ERC20Interface {
    function transfer(
        address to,
        uint256 tokens
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(address from, address to) external returns (uint256);
    // other ERC20 functions...
}

contract Xen3D {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlybelievers() {
        require(myTokens() > 0);
        _;
    }

    // only people with profits
    modifier onlyhodler() {
        require(myDividends(true) > 0);
        _;
    }

    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
        _;
    }

    modifier antiEarlyWhale(uint256 _amountOfEthereum) {
        address _customerAddress = msg.sender;

        if (
            onlyAmbassadors &&
            ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_)
        ) {
            require(
                // is the customer in the ambassador list?
                ambassadors_[_customerAddress] == true &&
                    // does the customer purchase exceed the max ambassador quota?
                    (ambassadorAccumulatedQuota_[_customerAddress] +
                        _amountOfEthereum) <=
                    ambassadorMaxPurchase_
            );

            // updated the accumulated quota
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(
                ambassadorAccumulatedQuota_[_customerAddress],
                _amountOfEthereum
            );

            // execute
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won't reinitiate
            onlyAmbassadors = false;
            _;
        }
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    // ERC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Xen3D";
    string public symbol = "X3D";
    uint8 public constant decimals = 18;
    uint8 internal constant dividendFee_ = 12; // Changed to 12%
    uint256 internal constant tokenPriceInitial_ = 0.0000001 ether;
    uint256 internal constant tokenPriceIncremental_ = 0.00000001 ether;
    uint256 internal constant magnitude = 2 ** 64;

    // proof of stake (defaults at 1 token)
    uint256 public stakingRequirement = 1e18;

    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 internal constant ambassadorMaxPurchase_ = 1 ether;
    uint256 internal constant ambassadorQuota_ = 1 ether;

    ERC20Interface public xenToken;
    ERC20Interface public XENDoge;

    /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    // administrator list (see above on what they can do)
    mapping(bytes32 => bool) public administrators;

    bool public onlyAmbassadors = false;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
     * -- APPLICATION ENTRY POINTS --
     */
    function Xen3D(address _xenTokenAddress, address _XENDogeAddress) public {
        xenToken = ERC20Interface(_xenTokenAddress);
        XENDoge = ERC20Interface(_XENDogeAddress);
        // add administrators here
        administrators[
            0x9bcc16873606dc04acb98263f74c420525ddef61de0d5f18fd97d16de659131a
        ] = true;

        ambassadors_[0x0000000000000000000000000000000000000000] = true;
    }

    /**
     * Converts all incoming Ethereum to tokens for the caller, and passes down the referral address (if any)
     */
    function buy(address _referredBy, uint256 amount) public returns (uint256) {
        purchaseTokens(amount, _referredBy);
    }

    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest() public onlyhodler {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }

    /**
     * Alias of sell() and withdraw().
     */
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw() public onlyhodler {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // delivery service
        // _customerAddress.transfer(_dividends);
        xenToken.transfer(_customerAddress, _dividends);

        // fire event
        onWithdraw(_customerAddress, _dividends);
    }

    /*
        For GandhiJi Contract:
            in Buy function
                total = 10%
                refferal = 3%
                fee = 10% token holder
            in Sell/transfer funtion
                total = 10%
                refferal = 0%
                fee = 10%
        For our Contract: 
            in Buy function
                total = 12%
                refferal = 3%
                fee = 5% token holder
                burn = 4% token holder
            in Sell/Transfer funtion
                total = 12%
                refferal = 0%
                fee = 7
                burn = 5
    */

    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens) public onlybelievers {
        address _customerAddress = msg.sender;

        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _incomingXEN = tokensToXEN_(_tokens);
        // uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        // uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        uint256 _undividedDividends = SafeMath.div(
            SafeMath.mul(_incomingXEN, 12),
            100
        ); // Changed to 12% tax
        uint256 _dividendsToXen3DHolders = SafeMath.div(
            _undividedDividends,
            12
        ) * 7; // 5% to Xen3D holders
        uint256 _burnAmount = SafeMath.div(_undividedDividends, 12) * 5; // 4% to burn
        uint256 _taxedXEN = SafeMath.sub(_incomingXEN, _undividedDividends);

        require(xenToken.transfer(XENDoge, _burnAmount));

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _tokens
        );

        // update dividends tracker
        int256 _updatedPayouts = (int256)(
            profitPerShare_ * _tokens + (_taxedXEN * magnitude)
        );
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                (_dividendsToXen3DHolders * magnitude) / tokenSupply_
            );
        }

        // fire event
        onTokenSell(_customerAddress, _tokens, _taxedXEN);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
     */
    function transfer(
        address _toAddress,
        uint256 _amountOfTokens
    ) public onlybelievers returns (bool) {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens

        require(
            !onlyAmbassadors &&
                _amountOfTokens <= tokenBalanceLedger_[_customerAddress]
        );

        // withdraw all outstanding dividends first
        if (myDividends(true) > 0) withdraw();

        // liquify 10% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(
            SafeMath.mul(_amountOfTokens, 12),
            100
        ); //SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);

        uint256 _undividedDividends = tokensToXEN_(_tokenFee);
        uint256 _dividendsToXen3DHolders = SafeMath.div(
            _undividedDividends,
            12
        ) * 7; // 5% to Xen3D holders
        uint256 _burnAmount = SafeMath.div(_undividedDividends, 12) * 5; // 4% to burn
        require(xenToken.transfer(XENDoge, _burnAmount));

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenBalanceLedger_[_toAddress] = SafeMath.add(
            tokenBalanceLedger_[_toAddress],
            _taxedTokens
        );

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256)(
            profitPerShare_ * _amountOfTokens
        );
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _taxedTokens);

        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(
            profitPerShare_,
            (_dividendsToXen3DHolders * magnitude) / tokenSupply_
        );

        // fire event
        Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;
    }

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * administrator can manually disable the ambassador phase.
     */
    function disableInitialStage() public onlyAdministrator {
        onlyAmbassadors = false;
    }

    function setAdministrator(
        bytes32 _identifier,
        bool _status
    ) public onlyAdministrator {
        administrators[_identifier] = _status;
    }

    function setStakingRequirement(
        uint256 _amountOfTokens
    ) public onlyAdministrator {
        stakingRequirement = _amountOfTokens;
    }

    function setName(string _name) public onlyAdministrator {
        name = _name;
    }

    function setSymbol(string _symbol) public onlyAdministrator {
        symbol = _symbol;
    }

    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance() public view returns (uint) {
        return this.balance;
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     */
    function myDividends(
        bool _includeReferralBonus
    ) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return
            _includeReferralBonus
                ? dividendsOf(_customerAddress) +
                    referralBalance_[_customerAddress]
                : dividendsOf(_customerAddress);
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(
        address _customerAddress
    ) public view returns (uint256) {
        return
            (uint256)(
                (int256)(
                    profitPerShare_ * tokenBalanceLedger_[_customerAddress]
                ) - payoutsTo_[_customerAddress]
            ) / magnitude;
    }

    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToXEN_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, 12), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToXEN_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, 12), 100);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(
        uint256 _ethereumToSpend
    ) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(
            SafeMath.mul(_ethereumToSpend, 12),
            100
        );
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = xenToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    function calculateEthereumReceived(
        uint256 _tokensToSell
    ) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToXEN_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, 12), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }

    function purchaseTokens(
        uint256 _incomingXEN,
        address _referredBy
    ) view antiEarlyWhale(_incomingXEN) returns (uint256) {
        address _customerAddress = msg.sender;
        require(
            xenToken.transferFrom(_customerAddress, address(this), _incomingXEN)
        );
        uint256 _undividedDividends = SafeMath.div(
            SafeMath.mul(_incomingXEN, 12),
            100
        ); // Changed to 12% tax
        uint256 _taxedXEN = SafeMath.sub(_incomingXEN, _undividedDividends);
        uint256 _amountOfTokens = xenToTokens_(_taxedXEN);

        require(
            _amountOfTokens > 0 &&
                (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_)
        );

        if (
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            referralBalance_[_referredBy] = SafeMath.add(
                referralBalance_[_referredBy],
                SafeMath.div(_undividedDividends, 12) * 3
            ); // 3% to referrer
        } else {
            _undividedDividends = SafeMath.add(
                _undividedDividends,
                SafeMath.div(_undividedDividends, 12) * 3
            ); // 3% to dividends
        }

        require(
            xenToken.transfer(
                XENDoge,
                SafeMath.div(_undividedDividends, 12) * 4
            )
        ); // 4% to burn

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += ((SafeMath.div(_undividedDividends, 12) *
                5 *
                magnitude) / tokenSupply_); // 5% to Xen3D holders
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );

        int256 _updatedPayouts = (int256)(
            (profitPerShare_ * _amountOfTokens) -
                (SafeMath.div(_undividedDividends, 12) * 5 * magnitude)
        );
        payoutsTo_[_customerAddress] += _updatedPayouts;

        // fire event
        onTokenPurchase(
            _customerAddress,
            _incomingXEN,
            _amountOfTokens,
            _referredBy
        );

        return _amountOfTokens;
    }

    // /*==========================================
    // =            INTERNAL FUNCTIONS            =
    // ==========================================*/
    // function purchaseTokens(uint256 _incomingXEN, address _referredBy)
    //     antiEarlyWhale(_incomingXEN)
    //     internal
    //     returns(uint256)
    // {
    //     // data setup
    //     address _customerAddress = msg.sender;
    //     uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingXEN, 12), 100);  // Changed to 12% tax
    //     uint256 _referralBonus = SafeMath.div(_undividedDividends, 12) * 3;  // 3% to referrer
    //     uint256 _dividendsToXen3DHolders = SafeMath.div(_undividedDividends, 12) * 5;  // 5% to Xen3D holders
    //     uint256 _burnAmount = SafeMath.div(_undividedDividends, 12) * 4;  // 4% to burn
    //     uint256 _taxedXEN = SafeMath.sub(_incomingXEN, _undividedDividends);
    //     uint256 _amountOfTokens = xenToTokens_(_taxedXEN);
    //     uint256 _fee = _dividendsToXen3DHolders * magnitude;

    //     require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

    //     // is the user referred by a karmalink?
    //     if(
    //         // is this a referred purchase?
    //         _referredBy != 0x0000000000000000000000000000000000000000 &&

    //         // no cheating!
    //         _referredBy != _customerAddress &&

    //         tokenBalanceLedger_[_referredBy] >= stakingRequirement
    //     ){
    //         // wealth redistribution
    //         referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
    //     } else {
    //         // no ref purchase
    //         // add the referral bonus back to the global dividends cake
    //         _dividendsToXen3DHolders = SafeMath.add(_dividendsToXen3DHolders, _referralBonus);
    //         _fee = _dividendsToXen3DHolders * magnitude;
    //     }

    //     require(xenToken.transfer(XENDoge, _burnAmount));

    //     // we can't give people infinite ethereum
    //     if(tokenSupply_ > 0){

    //         // add tokens to the pool
    //         tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

    //         // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
    //         profitPerShare_ += (_dividendsToXen3DHolders * magnitude / (tokenSupply_));

    //         // calculate the amount of tokens the customer receives over his purchase
    //         _fee = _fee - (_fee-(_amountOfTokens * (_dividendsToXen3DHolders * magnitude / (tokenSupply_))));

    //     } else {
    //         // add tokens to the pool
    //         tokenSupply_ = _amountOfTokens;
    //     }

    //     // update circulating supply & the ledger address for the customer
    //     tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

    //     int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
    //     payoutsTo_[_customerAddress] += _updatedPayouts;

    //     // fire event
    //     // onTokenPurchase(_customerAddress, _incomingXEN, _amountOfTokens, _referredBy);

    //     return _amountOfTokens;
    // }

    function calculateTokenPrice(
        uint256 _ethereum
    ) public view returns (uint256) {
        uint256 _tokensReceived = xenToTokens_(_ethereum);
        return _ethereum / _tokensReceived;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function xenToTokens_(uint256 _ethereum) public view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = ((
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    sqrt(
                        (_tokenPriceInitial ** 2) +
                            (2 *
                                (tokenPriceIncremental_ * 1e18) *
                                (_ethereum * 1e18)) +
                            (((tokenPriceIncremental_) ** 2) *
                                (tokenSupply_ ** 2)) +
                            (2 *
                                (tokenPriceIncremental_) *
                                _tokenPriceInitial *
                                tokenSupply_)
                    )
                ),
                _tokenPriceInitial
            )
        ) / (tokenPriceIncremental_)) - (tokenSupply_);

        return _tokensReceived;
    }

    /**
     * Calculate token sell value.
     */
    function tokensToXEN_(uint256 _tokens) public view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived = (// underflow attempts BTFO
        SafeMath.sub(
            (((tokenPriceInitial_ +
                (tokenPriceIncremental_ * (_tokenSupply / 1e18))) -
                tokenPriceIncremental_) * (tokens_ - 1e18)),
            (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
        ) / 1e18);
        return _etherReceived;
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * Also in memory of JPK, miss you Dad.
     */
}
