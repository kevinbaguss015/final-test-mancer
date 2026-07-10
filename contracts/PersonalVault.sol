// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PersonalVault {

    // ------------------------------------------------------------------
    // State Variables - Tempat nyimpen data utama contract
    // ------------------------------------------------------------------

    // Nyimpen alamat wallet yang punya contract ini
    address public owner;

    // Nyimpen waktu kapan dana boleh diambil
    uint256 public unlockTime;

    // ------------------------------------------------------------------
    // Events - Buat nyatet aktivitas penting di blockchain
    // ------------------------------------------------------------------

    // Event saat ada ETH yang berhasil disimpan
    event Deposit(address indexed sender, uint256 amount);

    // Event saat owner berhasil mengambil seluruh saldo
    event Withdrawal(uint256 amount, uint256 timestamp);

    // Event saat owner menambah waktu lock
    event LockExtended(uint256 newUnlockTime);

    // ------------------------------------------------------------------
    // Custom Errors - Error yang lebih hemat gas
    // ------------------------------------------------------------------

    // Error kalau dana masih terkunci
    error FundsLocked();

    // Error kalau yang manggil bukan owner
    error NotOwner();

    // Error kalau waktu unlock baru tidak valid
    error InvalidUnlockTime();

    // ------------------------------------------------------------------
    // Modifier - Biar cuma owner yang boleh akses
    // ------------------------------------------------------------------

    // Modifier ini ngecek apakah yang manggil fungsi adalah owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // ------------------------------------------------------------------
    // Constructor - Jalan sekali saat contract dibuat
    // ------------------------------------------------------------------

    // Constructor dijalankan saat contract pertama kali dibuat
    // Di sini owner disimpan dan waktu unlock ditentukan
    constructor(uint256 _unlockTime) payable {

        // Pastikan waktu unlock harus lebih besar dari waktu sekarang
        require(
            _unlockTime > block.timestamp,
            "Unlock time must be in the future"
        );

        // Yang deploy contract otomatis jadi owner
        owner = msg.sender;

        // Simpan waktu unlock
        unlockTime = _unlockTime;
    }

    // ------------------------------------------------------------------
    // Deposit Function
    // ------------------------------------------------------------------

    // Fungsi ini dipakai owner buat nyimpen ETH ke dalam contract
    // Nilai ETH dikirim lewat msg.value
    function deposit() external payable onlyOwner {

        // Catat transaksi deposit ke blockchain
        emit Deposit(msg.sender, msg.value);
    }

    // ------------------------------------------------------------------
    // Withdraw Function
    // ------------------------------------------------------------------

    // Fungsi ini dipakai owner buat mengambil semua ETH
    // Tapi cuma bisa dilakukan kalau waktu lock sudah selesai
    function withdraw() external onlyOwner {

        // Kalau waktunya belum lewat, transaksi dibatalin
        if (block.timestamp < unlockTime) {
            revert FundsLocked();
        }

        // Ambil seluruh saldo contract
        uint256 amount = address(this).balance;

        // Pastikan contract masih punya saldo
        require(amount > 0, "No balance");

        // Kirim semua ETH ke owner
        (bool success, ) = payable(owner).call{value: amount}("");

        require(success, "Transfer failed");

        // Catat transaksi withdraw
        emit Withdrawal(amount, block.timestamp);
    }

    // ------------------------------------------------------------------
    // Extend Lock Function
    // ------------------------------------------------------------------

    // Fungsi ini dipakai owner buat nambah waktu lock
    // Waktu lock cuma boleh ditambah, tidak boleh dikurangi
    function extendLock(uint256 newTime) external onlyOwner {

        // Pastikan waktu baru lebih besar dari waktu unlock sebelumnya
        if (newTime <= unlockTime) {
            revert InvalidUnlockTime();
        }

        // Update waktu unlock
        unlockTime = newTime;

        // Catat perubahan waktu lock
        emit LockExtended(newTime);
    }

    // ------------------------------------------------------------------
    // Receive Function
    // ------------------------------------------------------------------

    // Fungsi ini otomatis jalan kalau owner kirim ETH langsung
    // ke alamat contract tanpa manggil fungsi deposit()
    receive() external payable onlyOwner {

        // Catat transaksi deposit
        emit Deposit(msg.sender, msg.value);
    }
}