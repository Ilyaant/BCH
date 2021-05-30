pragma solidity >=0.4.22 <0.9.0;

contract MafiaCookies {
    //Уведомление о переводе токенов
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Подтверждение перевода токенов
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string private constant _name = "MafiaCookies"; // имя токена
    string private constant _symbol = "MC"; // символ (сокращенное название) токена
    uint256 private constant _decimals = 18; // максимальное количество дробных цифр после запятой
    uint256 private constant _totalSupply = 10000; // общее количество токенов в блокчейне

    mapping(address => uint256) public balances; // балансы всех игроков
    mapping(address => mapping(address => uint256)) allowed; // соответствие: адрес -> адрес, который может снять с него токены, -> количество этих токенов

    constructor () public {
        balances[msg.sender] = _totalSupply;
    }

    //Возвращает имя токена
    function name() public pure returns(string memory) {
        return _name;
    }

    //Возвращает символ токена
    function symbol() public pure returns(string memory) {
        return _symbol;
    }

    //Возвращает максимальное количество дробных цифр после запятой
    function decimals() public pure returns(uint256) {
        return _decimals;
    }

    //Возвращает общее количество токенов в блокчейне
    function totalSupply() public pure returns(uint256) {
        return _totalSupply;
    }
    
    //Количество токенов, приписанных к определенному адресу
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    //Возвращает текущее количество токенов, которое _spender может снять с _owner, установленное в функции approve()
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    //Передача токенов пользователю
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Out of mafia cookies");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //Совершение транзакций между пользователями
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from], "Out of mafia cookies");
        require(_value <= allowed[_from][msg.sender], "Out of allowance limit");

        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;      
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    //Подтверждает данному адресу (_spender) право отзывать токены (в количестве _value) с адреса владельца (msg.sender)
    function approve(address _spender, uint256 _value) public returns (bool) {
       allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
       return true;
    }
}