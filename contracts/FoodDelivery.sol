// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";


contract FoodDelivery is ERC1155,Ownable,Pausable{
constructor()ERC1155(""){



}

 using Counters for Counters.Counter;
    Counters.Counter hotelCount;
    //the nft if for hotel registration is 1,for the user nft is 2
    Counters.Counter nftIdCount; 
    Counters.Counter[] discountNftIdCount;


 struct Hotel{
        string hotelName; 
        address hotelAddress; 
        address hotelDeposit; 
        uint256 hotelId; 
    }
 struct HotelFoodItems{
     string[] foodItems;
 }   

 //here the nft id are stored for example when the new hotel gets registered the Nft of Id  1 is deposited to the user
 //simiarly to the user who orders gets the thanku nft which has the nft id of 2 and etc   
 struct NftIds{
    uint nftId;
    uint256 totalSupply;
 }  


    NftIds[] public getThePurposeOfNftIds;
    Hotel[] registeredHotels;
    HotelFoodItems[] listOfFoodItems;
    uint256[] totalBill;
    uint256 public minBill;
    mapping (string => NftIds) public idToNfts;
    mapping  (address=>mapping(address => bool)) public whitelisteManager;
    mapping (address=>mapping(string=>uint)) public hotelId;
    mapping (uint=>HotelFoodItems) storeFoodItems;
  //the cost of the food in the particular hotel  ex:in hotel x the biriyani costs 100rs  foodPrice[x][biriyani]=100rs
    mapping(uint256=>mapping(string=>uint256)) foodPrice;
    mapping(uint256 => uint256) internal discountNftToken;
    mapping (uint256=>uint256) internal discountNftTotalsupply;


    event orderedFood(string hotelName,address hotelAddress,string[] orderedFood,uint256 totalBill);


    //when hotel gets registered the manager of the hotel get the Nft as the proof use in the future for the hotel registration the nftId will be 1


//the hotel needs to be registered by hotel manager
    function registetHotel(string memory hotelName,address hotelDeposit) external {

        require(whitelisteManager[owner()][msg.sender] == true,"hotelManger need to get approval from the owner");
        require(hotelDeposit != msg.sender && hotelDeposit != address(0),"check the rules" );
        string memory _purpose = "Hotel";

        hotelCount.increment();
        uint Id = hotelCount.current();
        Hotel memory registered = Hotel(hotelName,msg.sender,hotelDeposit,Id);

       

        _mint(msg.sender,idToNfts[_purpose].nftId,1,"");
        
        idToNfts[_purpose].totalSupply++;

        registeredHotels.push(registered);
        hotelId[msg.sender][hotelName] = Id; 

    }
    function removeHotel(string memory _hotelName,address _hotelManager ) external  onlyOwner returns(uint256){
        string memory _purpose = "Hotel";
        require(whitelisteManager[msg.sender][_hotelManager] == true,"hotelManger need to get approval from the owner");
        require( balanceOf(msg.sender, idToNfts[_purpose].nftId)>0,"the hotel manager is missing the hotel registration nft ");

        uint256 getHotelId = hotelId[_hotelManager][_hotelName];
        uint256 length = registeredHotels.length;
         
    
        for(uint256 i=0;i< length;i++){
            if(registeredHotels[i].hotelId==getHotelId){
                _burn(_hotelManager,idToNfts[_purpose].nftId,1);
                registeredHotels[i] = registeredHotels[length-1];
                registeredHotels.pop();
                idToNfts[_purpose].totalSupply--;
                delete hotelId[_hotelManager][_hotelName]; 
                return getHotelId;

            }
        }
}


      function changeHotelAddress(address _newAddress,string memory _hotelName) external returns(address ){
          string memory _purpose = "Hotel";
          require(whitelisteManager[owner()][msg.sender] == true,"hotelManger need to get approval from the owner");
          require(_newAddress != address(0),"cant the make the zero address as the manager");
          require( balanceOf(msg.sender, idToNfts[_purpose].nftId)>0,"the hotel is missing the hotel registration nft ");
          uint256 _Id = hotelId[msg.sender][_hotelName];
              
               uint256 count;
               uint256 length = registeredHotels.length;
               for(uint256 i=0;i<length;i++){
                   if(_Id== registeredHotels[i].hotelId){
                       //internal function erc1155
                       _safeTransferFrom(msg.sender, _newAddress,idToNfts[_purpose].nftId ,1,"");
                       whitelisteManager[owner()][msg.sender] = false;
                       registeredHotels[i].hotelAddress = _newAddress;
                       hotelId[_newAddress][_hotelName] = _Id;
    }
                   count++;
               }
               if(count== length){
                   revert("hotel is not registered");
               }
                
               return _newAddress;
               //new manager should get the approval from the owner
 } 

 


    function hotelAddressGetApproveFromOwner(address hotelAddress,bool check) external  onlyOwner returns(bool){
        return whitelisteManager[msg.sender][hotelAddress] = check;


    } 

    function checkRegisteredHotels() public view returns(Hotel[] memory){
        return  registeredHotels;
    }


    function addNewNftType(string memory _purpose, uint256 _totalSupply) external onlyOwner returns(uint256 _idNo ){
        nftIdCount.increment();
         _idNo = nftIdCount.current();
    

          idToNfts[_purpose] = NftIds({
              nftId:_idNo,
              totalSupply:_totalSupply
          });
        getThePurposeOfNftIds.push(idToNfts[_purpose]);

    }

    function updateTotalSupplyOfNft(string memory _purpose,uint256 _totalsupply) external onlyOwner  {
      
       idToNfts[_purpose].totalSupply = idToNfts[_purpose].totalSupply +_totalsupply;
       
       }
    function getNftIdPurpose() public view returns(NftIds[] memory){
        return getThePurposeOfNftIds;
    }

    //list the hotel items hotel wise

    // function listHotelFoodItems(string memory _hotelName,string[] memory _foodItems,uint256[] memory _price) external  {
    //      string memory _purpose = "Hotel";
    //      require(whitelisteManager[owner()][msg.sender] == true,"hotelManger need to get approval from the owner");
    //      require( balanceOf(msg.sender, idToNfts[_purpose].nftId)>0,"the hotel manager is missing the hotel registration nft ");
    //      require(_foodItems.length==_price.length,"price and noof items should be of the same length");
    //       uint256 getHotelId = hotelId[msg.sender][_hotelName];

    //       storeFoodItems[getHotelId].foodItems = _foodItems;

    //       for(uint256 i=0;i<_foodItems.length;i++){
    //       foodPrice[getHotelId][_foodItems[i]] = _price[i] ;

    //       }
        // }

function listHotelFoodItemsOrUpdatePrice(string memory _hotelName,string[] memory _foodItems,uint256[] memory _price,bool updatePrice ) external{
     string memory _purpose = "Hotel";
         require(whitelisteManager[owner()][msg.sender] == true,"hotelManger need to get approval from the owner");
         require( balanceOf(msg.sender, idToNfts[_purpose].nftId)>0,"the hotel manager is missing the hotel registration nft ");
         require(_foodItems.length==_price.length,"price and noof items should be of the same length");

         uint256 getHotelId = hotelId[msg.sender][_hotelName];

         if(!updatePrice){
             
         for(uint256 i=0;i<_foodItems.length;i++){
              storeFoodItems[getHotelId].foodItems.push(_foodItems[i]);
             foodPrice[getHotelId][_foodItems[i]] = _price[i] ;
         }
         }
         else{
          uint256 length = storeFoodItems[getHotelId].foodItems.length;
          uint256 count;
                 
            for(uint256 i=0;i<_foodItems.length;i++){
                for(uint256 j=0;j<length;j++){
                    if(keccak256(abi.encodePacked((_foodItems[i]))) == keccak256(abi.encodePacked((storeFoodItems[getHotelId].foodItems[j])))){
                        foodPrice[getHotelId][_foodItems[i]] = _price[i];
                    }
                  }
                  count++;
            }
            if(count == _foodItems.length){
                revert("food item doesnt exist");
            }
         }
        }

         


function setMinBill(uint256 _minBill) external onlyOwner{
    minBill = _minBill;
}


function foodMenu(address _hotelManager,string memory _hotelName) public view returns(string[] memory){
     uint256 getHotelId = hotelId[_hotelManager][_hotelName];
    return storeFoodItems[getHotelId].foodItems;

}

//if user buys the food item he gets the userNFT as the coupen where he can them in the future to get the descounts 
function orderFood(string memory _hotelName,address _hotelManager,string[] memory _foodItem)public  returns(uint256 _totalBill){
    string memory empty = "";
    
     require( keccak256(abi.encodePacked((_hotelName))) != keccak256(abi.encodePacked((empty))),"enter any food items");
     require(_hotelManager != address(0),"hotel address cannot be zero");

    uint256 getHotelId = hotelId[_hotelManager][_hotelName];

    string[] memory _foodItems =  storeFoodItems[getHotelId].foodItems;

    for(uint256 i=0;i<_foodItem.length;i++){
         require( keccak256(abi.encodePacked((_foodItem[i]))) != keccak256(abi.encodePacked((empty))),"enter any food items");
        for(uint256 j=0;j<_foodItems.length;j++){
            if( keccak256(abi.encodePacked((_foodItem[i]))) == keccak256(abi.encodePacked((_foodItems[j])))){
               uint256 _price = foodPrice[getHotelId][_foodItems[j]];
               _totalBill += _price;
                 }
        }
    emit orderedFood(_hotelName,_hotelManager,_foodItem,_totalBill);
    //based on the totalbill the users will get the discount nfts
     //500 = [100,200,300,400,500,600]
  
          for(uint256 i=0;i<totalBill.length;i++){
              if(_totalBill<=totalBill[i]&&_totalBill>minBill){
                 discountNftIdCount[i].increment();
                  uint256 _current = discountNftIdCount[i].current();
                  require(_current<=discountNftTotalsupply[totalBill[i]],"all discount nfts are disturbuted ");

                   _mint(msg.sender,discountNftToken[totalBill[i]],1,"");
                   }
                   
            }
    }

      
}

// function acceptOrdersByResturens()
//need to add the purpose addNewNftType(string memory _purpose, uint256 _totalSupply) 
function setDiscountNftBasedOnTotalBill(uint256[] memory _totalBill,string[] memory _purpose) external onlyOwner{
    require(_totalBill.length==_purpose.length,"both should be equal ");
    //_purpose = "10% discount "
    //_purpose = "20% discount
    
    for(uint256 i = 0;i<_totalBill.length;i++){
        discountNftToken[_totalBill[i]] = idToNfts[_purpose[i]].nftId;
        discountNftTotalsupply[_totalBill[i]] = idToNfts[_purpose[i]].totalSupply;

        totalBill.push(_totalBill[i]);

    }
}


  }



  

