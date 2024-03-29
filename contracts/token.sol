// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

}

interface IUniswapV2Router02 is IUniswapV2Router01 {

}

interface IUniswapV2Factory {
    
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}

contract TGKToken is ERC20, Ownable {
    uint256 public buyTax = 7500;
    uint256 public sellTax = 7500;
    address public taxDistributionContract = 0x50Ca1fde29D62292a112A72671E14a5d4f05580f;
    mapping(address => bool) public excludedFromTax;
    uint256 public maxBuy = 7500000000000000000000000;
    uint256 public maxSell = 7500000000000000000000000;
    uint256 public maxHolding = 20000000000000000000000000;
    address public automatedMarketMakerPairsContract;
    mapping(address => bool) public isBlacklisted;

    // events
    event TokenBurnt(address wallet, uint256 amount);
    event WalletFeeUpdated(address wallet , bool isExcluded);
    event BlacklistAddressUpdated(address wallet, bool isBlacklisted);
    event MaxBuyUpdated(uint256 maxBuy);
    event MaxSellUpdated(uint256 maxSell);
    event buyTaxUpdated(uint256 tax);
    event sellTaxUpdated(uint256 tax);
    event automatedMarketMakerPairsContractUpdated(address automatedMarketMakerPairs);
    event TaxDistributionContractUpdated(address taxDistributionContract);
    event TokenAirDropped(address user, uint256 amount);
    event MaxHoldingUpdated(uint256 max);

    constructor()  ERC20("The Gamble Kingdom", "TGK") {
        _mint(msg.sender, 1000000000000000000000000000);

        excludedFromTax[msg.sender] = true;

         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
        );
        automatedMarketMakerPairsContract = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());


    }
    
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
        emit TokenBurnt(account, amount);
    }

    function updateWalletFee(address wallet, bool isExcluded) external onlyOwner{
        excludedFromTax[wallet] = isExcluded;
        emit WalletFeeUpdated(wallet, isExcluded);
    }

    function updateBlacklist(address wallet, bool _isBlacklisted) external onlyOwner{
        isBlacklisted[wallet] = _isBlacklisted;
        emit BlacklistAddressUpdated(wallet, _isBlacklisted);
    }

    function updateMaxBuy(uint256 _maxBuy) external onlyOwner{
        maxBuy = _maxBuy;
        emit MaxBuyUpdated(_maxBuy);
    }

    function updateMaxSell(uint256 _maxSell) external onlyOwner{
        maxSell = _maxSell;
        emit MaxSellUpdated(_maxSell);
    }
    function updateBuyTax(uint256 tax) external onlyOwner{
        buyTax = tax;
        emit buyTaxUpdated(tax);
    }

    function updateautomatedMarketMakerPairsContract(address _automatedMarketMakerPairs) external onlyOwner{
        automatedMarketMakerPairsContract = _automatedMarketMakerPairs;
        emit automatedMarketMakerPairsContractUpdated(_automatedMarketMakerPairs);
    }

    function updateTaxDistributionContract(address _taxDistributionContract) external onlyOwner{
        taxDistributionContract = _taxDistributionContract;
        emit TaxDistributionContractUpdated(_taxDistributionContract);
    }

    function updateMaximumHolding(uint256 max) external onlyOwner{
        maxHolding = max;
        emit MaxHoldingUpdated(max);
    }

    function airdropTokens(address[] memory users, uint256[] memory amount) external onlyOwner{
        require(users.length == amount.length,"Invalid input");
        uint256 total = users.length;
        for(uint256 i=0; i< total ; i++){
            _transfer(msg.sender, users[i], amount[i]);
            emit TokenAirDropped(users[i], amount[i]);
        }
 
    }

    

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override{   
        require(isBlacklisted[sender]!= true || isBlacklisted[recipient]!= true,"Address Blacklisted");   
            if(sender == automatedMarketMakerPairsContract && (excludedFromTax[sender]==false && excludedFromTax[recipient] == false)){
                require(balanceOf(recipient)+amount <= maxHolding,"Maximum Holding Amount Exceeded");
                require(amount <= maxBuy,"Amount exceeds the Max Buy Value");
                uint256 taxAmount= amount*(buyTax)/(100000);
                super._transfer(sender,taxDistributionContract,taxAmount);
                super._transfer(sender,recipient,amount-(taxAmount));
            }
            else if(recipient == automatedMarketMakerPairsContract && (excludedFromTax[sender]==false && excludedFromTax[recipient] == false)){
                require(amount <= maxSell,"Amount exceeds the Max Sell Value");
                uint256 taxAmount= amount*(sellTax)/(100000);
                super._transfer(sender,taxDistributionContract,taxAmount);
                super._transfer(sender,recipient,amount-(taxAmount));
            }
            else{
                super._transfer(sender,recipient,amount);
            }
            
        
        
    }
}
