const { assert } = require("chai");

const Mafia = artifacts.require("Mafia");
const MC = artifacts.require("MafiaCookies");

contract('Mafia - basic', (accounts) => {
    describe('Starting tokens', () => {
        let instance;
        let mc;
        before(async () => {
            instance = await Mafia.deployed();
            mc = await MC.at(await instance.token());
            for (let i = 0; i < 10; ++i) {
                await instance.Ask({from: accounts[i]});
            }
            await instance.gameStart();
        });
        after(async () => {
            await instance.Reset();
        });
        it('should put 100 MC to each account at start', async () => {
            for (let i = 0; i < 10; ++i) {
                let balance = await mc.balanceOf(accounts[i]);
                assert.equal(balance, 100, `100 wasn't in the ${i} account`);
            }
        });
    });
    
    describe('Players turns', () => {
        let instance;
        beforeEach(async () => {
            instance = await Mafia.deployed();
            for (let i = 0; i < 10; ++i) {
                await instance.Ask({from: accounts[i]});
            }
            await instance.gameStart();
        });
        afterEach(async () => {
            await instance.Reset();
        });
        it('should kill mafias victim', async () => {
            await instance.MafiaKill(5);
            await instance.PolicemanFind(5, {from: accounts[8]});
            await instance.DoctorHeal(6, {from: accounts[5]});
            const check_alive = (await instance.getStateP(5)).toString();
            const st = (await instance.getState(0)).toString();
            assert.equal(check_alive, st, 'mafia is not able to kill');
        });
        it('should heal', async () => {
            await instance.MafiaKill(5);
            await instance.PolicemanFind(5, {from: accounts[8]});
            await instance.DoctorHeal(5, {from: accounts[5]});
            const check_alive = (await instance.getStateP(5)).toString();
            const st = (await instance.getState(1)).toString();
            assert.equal(check_alive, st, 'doctor is not able to heal');
        });
        it('should find citizen', async () => {
            await instance.MafiaKill(5);
            await instance.PolicemanFind(9, {from: accounts[8]});
            await instance.DoctorHeal(5, {from: accounts[5]});
            const check_index = (await instance.getRolesArr(9)).toString();
            const r = (await instance.getRole(4)).toString();
            assert.equal(check_index, r, 'policeman is not able to find citizen');
        });
        it('should find mafia', async () => {
            await instance.MafiaKill(5);
            await instance.PolicemanFind(1, {from: accounts[8]});
            await instance.DoctorHeal(5, {from: accounts[5]});
            const check_index = (await instance.getRolesArr(1)).toString();
            const r = (await instance.getRole(1)).toString();
            assert.equal(check_index, r, 'policeman is not able to find mafia');
        });
    });
});

contract ('Mafia - bets and prizes', (accounts) => {
    describe('Bets', () => {
        let instance;
        let mc;
        beforeEach(async () => {
            instance = await Mafia.deployed();
            mc = await MC.at(await instance.token());
            for (let i = 0; i < 10; ++i) {
                await instance.Ask({from: accounts[i]});
            }
            await instance.gameStart();
            for (let i = 0; i < 10; ++i) {
                await mc.approve(instance.address, 100, {from: accounts[i]});
            }
        });
        afterEach(async () => {
            await instance.Reset();
        });
        it('should take bets', async () => {
            for (let i = 0; i < 10; ++i) {
                await instance.Bet(100, {from: accounts[i]});
                let balance = (await mc.balanceOf(accounts[i])).toString();
                assert.equal(balance, '0', 'bets taken unsuccessfully');
            }
        });
        it('should have mafias bets', async () => {
            for (let i = 0; i < 10; ++i) {
                await instance.Bet(100, {from: accounts[i]});
            }
            const bet = (await instance.mafia_bets()).toString();
            assert.equal(bet, '300', 'mafias bets count wrong');
        });
        it('should have citizens bets', async () => {
            for (let i = 0; i < 10; ++i) {
                await instance.Bet(100, {from: accounts[i]});
            }
            const bet = (await instance.citizen_bets()).toString();
            assert.equal(bet, '700', 'citizen bets count wrong');
        });
    });

    describe('Prizes', () => {
        let instance;
        let mc;
        beforeEach(async () => {
            instance = await Mafia.deployed();
            mc = await MC.at(await instance.token());
            for (let i = 0; i < 10; ++i) {
                await mc.approve(instance.address, 100, {from: accounts[i]});
            }
            for (let i = 0; i < 10; ++i) {
                await instance.Ask({from: accounts[i]});
            }
            await instance.gameStart();
        });
        afterEach(async () => {
            await instance.Reset();
        });
        it('should give prize to mafias if they win', async () => {
            for (let i = 0; i < 10; ++i) {
                await instance.Bet(100, {from: accounts[i]});
            }
            await instance.MafiaWin();
            for (let i = 0; i < 3; ++i) {
                let balance = (await mc.balanceOf(accounts[i])).toString();
                assert.equal(balance, '333', 'mafias havent received the prize');
            }
        });
        it('should give prize to citizens if they win', async () => {
            for (let i = 0; i < 10; ++i) {
                await instance.Bet(100, {from: accounts[i]});
            }
            await instance.CitizenWin();
            for (let i = 3; i < 10; ++i) {
                let balance = (await mc.balanceOf(accounts[i])).toString();
                assert.equal(balance, '142', 'citizens havent received the prize');
            }
        });
    });
});