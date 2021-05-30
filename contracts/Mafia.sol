pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./MafiaCookies.sol";

contract Mafia {
    MafiaCookies token = new MafiaCookies();

    /*constructor (MafiaCookies _token) public {
        token = _token;
    }*/

    // возможные роли и стадии игры
    enum Roles { 
        UNKNOWN,
        GAMESTART,
        MAFIA, 
        POLICEMAN, 
        DOCTOR, 
        CITIZEN,
        STOPGAME
    } 

    // возможные состояния игрока
    enum States {
        ALIVE,
        DEAD
    }

    function getStateP(uint ind) public view returns (States) {
        return players[ind].state;
    }

    function getState(uint ind) public pure returns (States) {
        if (ind == 0) return States.DEAD;
        else return States.ALIVE;
    }

    function getRoleP(uint ind) public view returns (Roles) {
        return players[ind].role;
    }

    function getRole(uint ind) public pure returns (Roles) {
        if (ind == 1) return Roles.MAFIA;
        else if (ind == 2) return Roles.POLICEMAN;
        else if (ind == 3) return Roles.DOCTOR;
        else return Roles.CITIZEN;
    }

    function getContractAddr() public view returns (address) {
        return address(this);
    }

    event Log(string _mystring);
    event Winside(Roles a, string b);
    event CurrentStage(Roles a);

    uint private constant num_of_players = 10; // количество игроков
    uint private leader = 0; // индекс текущего босса мафии, делающего выбор
    uint private mafia_count = 3; // количество мафий
    uint private peaceful_count = 7; // количество мирных
    uint private doctor_index = 5; //индекс доктора
    uint private policeman_index = 8; //индекс полицейского
    uint private hit = 11; // индекс игрока, в которого попали
    uint private voted = 0; // количество проголосовавших
    uint private index = 0; // индекс для заполнения массива вошедших игроков
    uint private bank = 0;
    uint private constant min_stake = 100;
    uint private constant welcoming_tokens = 100; // приветственные токены
    uint private mafia_bets = 0; // ставки мафии
    uint private citizen_bets = 0; // ставки жителей

    uint[num_of_players] private voted_already; // проголосовавшие игроки
    uint[num_of_players] private voted_for; // игроки, за которых проголосовали

    Roles[num_of_players] private roles_arr;

    function getRolesArr(uint ind) public view returns (Roles) {
        return roles_arr[ind];
    }

    Player[num_of_players] private players; // игроки

    function getPlayers(uint ind) public view returns (Player memory) {
        return players[ind];
    }

    Roles private stage = Roles.STOPGAME; // стадия игры

    address[num_of_players] private Users; // адреса вошедших игроков

    mapping(address => uint) public players_roles; // соотношение адрес - индекс
    
    mapping(string => Roles) public lookup; // соотношение строка - роль
    
    // игрок и его характеристики
    struct Player {
        States state;
        Roles role;
        address adr;
    }

    // вход игрока в игру
    function Ask() 
    public 
    avaliable() 
    {
        Users[index] = msg.sender;
        players_roles[msg.sender] = index;
        index++;
    }

    function Bet(uint256 stake)
    public
    ActiveGame()
    {
        require(stage == Roles.GAMESTART, "Bets are no longer accepted!");
        require(stake >= min_stake, "Less than min stake"); 
        require(token.balanceOf(msg.sender) >= stake, "Not enough");
        bank += stake;
        uint ind = players_roles[msg.sender];
        if (players[ind].role == Roles.MAFIA) {
            mafia_bets += stake;
        } else {
            citizen_bets += stake;
        }
        token.transferFrom(msg.sender, address(this), stake);
    }

    function Mafia_Bets() 
    public
    view 
    returns(uint256) {
        return mafia_bets;
    }

    function Citizen_Bets() 
    public
    view 
    returns(uint256) {
        return citizen_bets;
    }

    function lookBalance(address addr) public view returns (uint) {
        return token.balanceOf(addr);
    }

    function tokApprove(address addr, uint val) public {
        token.approve(addr, val);
    }

    // начало игры
    function gameStart() 
    public 
    full() 
    {       
        emit Log("HELLOOOOOOOO!!!!!!!!!!!!!!!!!"); // приветствие
        for (uint i = 0; i < num_of_players; i += 1) {
            players[i].state = States.ALIVE;
            players[i].adr = Users[i];
            token.transfer(Users[i], welcoming_tokens);
        }
        players[0].role = Roles.MAFIA;
        players[1].role = Roles.MAFIA;
        players[2].role = Roles.MAFIA;
        players[3].role = Roles.CITIZEN;
        players[4].role = Roles.CITIZEN;
        players[5].role = Roles.DOCTOR;
        players[6].role = Roles.CITIZEN;
        players[7].role = Roles.CITIZEN;
        players[8].role = Roles.POLICEMAN;
        players[9].role = Roles.CITIZEN;
        lookup["MAFIA"] = Roles.MAFIA;
        lookup["CITIZEN"] = Roles.CITIZEN;
        lookup["DOCTOR"] = Roles.DOCTOR;
        lookup["POLICEMAN"] = Roles.POLICEMAN;
        stage = Roles.GAMESTART;
        bank = 0;
        mafia_bets = 0;
        citizen_bets = 0;
    }

    // ход мафии
    function MafiaKill(uint ind) 
    public 
    roleCheck(Roles.MAFIA)
    ActiveGame()
    mafia_settled(ind) 
    {
        do { // передача должности босса мафии по очереди
            leader = (leader + 1) % 3;
        } while (players[leader].state == States.DEAD);
        hit = ind;
        if (players[policeman_index].state == States.ALIVE) { // ход полицейского начинается только если мафия его не убила
            stage = Roles.POLICEMAN;
            emit CurrentStage(Roles.POLICEMAN);
        }
        else if (players[doctor_index].state == States.ALIVE) { // ход врача начинается только если мафия его не убила
            stage = Roles.DOCTOR;
            emit CurrentStage(Roles.DOCTOR);
        }
        else { // если врач и полицейский мертвы, ход переходит к мирным жителям
            stage = Roles.CITIZEN;
            players[hit].state = States.DEAD;
            peaceful_count--;
            if (mafia_count >= peaceful_count)  // победа мафии
                MafiaWin();
            emit CurrentStage(Roles.CITIZEN);
        }
    }

     // ход полицейского
    function PolicemanFind(uint ind) 
    public 
    roleCheck(Roles.POLICEMAN)
    ActiveGame()
    policeman_settled(ind)
    { 
        if (players[doctor_index].state == States.ALIVE || hit == doctor_index) { // ход врача начинается только если мафия его не убила
            stage = Roles.DOCTOR;
            emit CurrentStage(Roles.DOCTOR);
        }
        else { // если врач мертв, ход переходит к мирным жителям
            stage = Roles.CITIZEN;
            players[hit].state = States.DEAD;
            emit CurrentStage(Roles.CITIZEN);
        }
        Roles[num_of_players] storage p_roles_arr = roles_arr;
        if (players[ind].role == Roles.MAFIA) { // заполнение списка подозреваемых
            p_roles_arr[ind] = Roles.MAFIA;
        } else {
            p_roles_arr[ind] = Roles.CITIZEN;
        }
    }

    // ход доктора
    function DoctorHeal(uint ind) 
    public 
    roleCheck(Roles.DOCTOR) 
    ActiveGame()
    correct_range(ind)
    {
        if (hit != ind) { // если врач не указал на "подбитого" (не вылечил), он умирает, счетчик мирных уменьшается
            peaceful_count--;
            players[hit].state = States.DEAD;
            if (mafia_count >= peaceful_count)  // победа мафии
                MafiaWin();
        }
        stage = Roles.CITIZEN; // переход хода мирным
        emit CurrentStage(Roles.CITIZEN);
    }

    // голосование
    function Vote(uint ind) 
    public 
    roleCheck(Roles.CITIZEN)
    ActiveGame() 
    {
        uint vote_count = voteCount();
        if (voted < vote_count && voted_already[players_roles[msg.sender]] == 0 && players[ind].state == States.ALIVE) {
            voted_for[ind] += 1;
            voted++;
        } 
        if (voted == vote_count) {
            uint max = 0;
            uint i_max = 0;
            for (uint i = 0; i < num_of_players; i++) {
                if (voted_for[i] > max) {
                    max = voted_for[i];
                    i_max = i;
                }
            }
            if (players[i_max].role == Roles.MAFIA) mafia_count--;
            else peaceful_count--;
            players[i_max].state = States.DEAD;
        }
        if (mafia_count >= peaceful_count) { // победа мафии
            MafiaWin();
        }
        else if (mafia_count == 0) { // победа мирных
            CitizenWin();
        }
        voted = 0;
        stage = Roles.MAFIA;
        emit CurrentStage(Roles.MAFIA);
    }
    
    function MafiaWin() 
    public
    {
       emit Winside(Roles.MAFIA, ":WIN");
       uint256 count = bank / 3;
       for (uint i = 0; i < 3; i++) {
           token.transfer(Users[i], count);
       }
       Reset();
       return;
    }

    function CitizenWin()
    public 
    {
        emit Winside(Roles.CITIZEN, ":WIN");
        uint256 count = bank / 7;
        for (uint i = 3; i < num_of_players; i++) {
           token.transfer(Users[i], count);
        }
        Reset();
        return;
    }

    // количество живых
    function CheckAlive() 
    public 
    view 
    returns(uint)
    {
        uint count = 0;
        for (uint i = 0; i < num_of_players; i += 1){
            if(players[i].state == States.ALIVE) count += 1;
        }
        return(count);
    }

    // проверка состояния (жив/мертв) для конкретного игрока
    function CheckAlive(uint ind) 
    public 
    view 
    correct_range(ind) 
    returns(uint)
    {
        uint count = 0;
        if (players[ind].state == States.ALIVE) count = 1;
        return(count);
    }

    // вывести роли подозреваемых полицейским
    function PolicemanReturn() 
    public 
    view 
    roleCheck(Roles.POLICEMAN) 
    returns (Roles[num_of_players] memory) 
    {
        return roles_arr;
    }

    // количество тех, за кого можно проголосовать (живых)
    function voteCount() 
    public 
    view 
    returns (uint) 
    {
        return (mafia_count + peaceful_count);
    } 
    
    // узнать индексы игроков по роли
    function RoleLookup(string calldata s) 
    external 
    view 
    returns (uint[] memory) 
    {
        uint k = 0;
        Roles rr = lookup[s];

        for (uint i = 0; i < num_of_players; i++) {
            if (players[i].role == rr) k++;
        }

        uint[] memory lookup_arr = new uint[](k);
        k = 0;

        for (uint i = 0; i < num_of_players; i++) {
            if (players[i].role == rr) {
                lookup_arr[k] = i;
                k++;
            }
        }
        return lookup_arr;
    }

     // возврат к начальным параметрам игры ("заводским настройкам")
    function Reset() 
    public 
    {
        stage = Roles.STOPGAME;
        index = 0;
        leader = 0;
        voted = 0;
        for (uint i = 0; i < num_of_players; i++) {
            voted_already[i] = 0;
        }
        for (uint i = 0; i < num_of_players; i++) {
            voted_for[i] = 0;
        }
        for (uint i = 0; i < num_of_players; i++) {
            roles_arr[i] = Roles.UNKNOWN;
        }
        hit = 11;
        mafia_count = 3;
        peaceful_count = 7;
    }

    // авторы
    function Credits() 
    public 
    pure 
    returns (string memory) 
    {
        return "Mafia Project by Antonov, Bagildinskaya, Bogomolov, Grigorieva, Karnaushko";
    }

    modifier ActiveGame() {
        require(stage != Roles.STOPGAME);
        _;
    }

    modifier avaliable() {
        require (
            index < num_of_players,
            "All game places are busy"
        );
        _;
    }

    modifier full() {
        require (
            index == num_of_players,
            "There are some more places"
        );
        _;
    }
    
    modifier roleCheck(Roles r) {
        bool flag = false;
        for (uint i = 0; i < num_of_players; i++) {
            if (players[i].adr == msg.sender) {
                if (players[i].role == r && stage == r) {
                    flag = true; 
                }
                break;
            }    
        }
        if (stage == Roles.GAMESTART && r == Roles.MAFIA) flag = true;
        require (flag);
        _;
    }

    modifier mafia_settled(uint ind) {
        uint id = players_roles[msg.sender];
        require(id == leader && ind < num_of_players && ind >= 3 && players[ind].state == States.ALIVE);
        _;
    }

    modifier policeman_settled(uint ind) {
        require(ind < num_of_players && ind != policeman_index && ind >= 0 && players[ind].state == States.ALIVE);
        _;
    }

    modifier correct_range(uint ind) {
        require(ind < num_of_players && ind >= 0 && players[ind].state != States.DEAD);
        _;
    }
}