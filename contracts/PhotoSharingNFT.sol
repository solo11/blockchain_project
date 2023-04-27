// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PhotoSharingNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, ERC721Burnable {
    using Counters for Counters.Counter;


    // define the structure of a post
    struct Post {
        string name;
        address owner;
        string uri;
        uint tokenId;
        uint price;
        bool forSale;
        uint uniqueScore;
        uint timestamp;
        string description;
    }

    // define the structure of a user
    struct user {
        string user_name;
    }

    address owner;

    mapping (address=>user) users;
    mapping (address=>uint) registration;
    Post[] posts;

    // modifiers defined 
    modifier onlyUser {
        require(registration[msg.sender]==1);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("PhotoSharingNFT", "STK") {
        owner = msg.sender;
        users[owner].user_name = "admin";
        registration[owner]= 1;
    }

    // A new user has to register 

    function register(string memory name) public {
        require(registration[msg.sender] != 1,'User already registered');
        address usr = msg.sender;       
        registration[usr]= 1;
        users[usr].user_name = name;
    }

    function unregister() public {
    address usr = msg.sender;       
    registration[usr]= 0;
    users[usr].user_name = "";
    }

    function getUsername()  public view returns(string memory){
        if(registration[msg.sender] == 1){
        return users[msg.sender].user_name;
        }
        return "user not registered";
    }

    // Owner can pause / unpause 
    function pauseContract() public onlyOwner {
        _pause();
    }
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // upload a new post, a user can upload the post by sending the uri of post metadata and name of the post
    // the post is added to the posts list

    function uploadPost(string memory uri,string memory name, string memory description) public onlyUser returns(uint256){
         uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        Post memory newPost = Post(name,msg.sender,uri,tokenId,0,false,0,block.timestamp,description);

        posts.push(newPost);

        return tokenId;
    }

    // toggle the post for sale or not 

    function toggleSale(uint tokenId, bool val) public onlyUser {
        require(msg.sender == posts[tokenId].owner,"Only owner can toggle");
        posts[tokenId].forSale = val;
    }

    // the owner of the post can set the post for sale and set the selling amount 

    function sellNFT(uint tokenId, uint amt) public onlyUser {
        require(msg.sender == posts[tokenId].owner,"Only owner can sell");
        if(posts[tokenId].forSale == false) {
            posts[tokenId].forSale = true;
        }
        posts[tokenId].price = amt;
    }

    // other registered users can buy the nft by sending in the amount
    // the ownership if the token gets transfered to the buyer

    function buyNFT(uint tokenId) payable public onlyUser {
        require(msg.sender != posts[tokenId].owner,"you already own the NFT");
        require(posts[tokenId].forSale = true,"the item is not up for sale");

        uint price = posts[tokenId].price;
        address owner_nft = ERC721.ownerOf(tokenId);
        
        require(msg.value == price, "Please submit the asking price");

        posts[tokenId].forSale = false;
        _tokenIdCounter.decrement();

        _transfer(owner_nft, msg.sender, tokenId);
        payable(owner_nft).transfer(msg.value);

    }    

    // increment and decrement the value 
    // an uniqueness scale value is assgned to each post which appreciates or depriciates the nft value 
    // A backed function assigns the value by evaluating the post with the other posts for uniqueness

    function assignUniqueScore(uint unique_score, uint tokenId) public onlyOwner {
        posts[tokenId].uniqueScore = unique_score;
    }

    // get all the data of a post given a token id

    function getPostData(uint tokenId) view public returns (Post memory){
         return(posts[tokenId]);
    }

    // returns the address of the owner

    function getOwner(uint id) view public returns (address){
        address owner_c = ERC721.ownerOf(id); 
        return owner_c;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    // The following functions are overrides required by Solidity.

    // The NFT can be burnt by the owner 
    function _burn (uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
