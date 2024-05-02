// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Rifa {
    uint256 public ultimaTransacaoId;
    struct Bilhete {
        address dono;
        bool vendido;
    }

    struct RifaInfo {
        uint256 id;
        string nomeRifa;
        string metadataURI;
        uint256 valorPremio;
        uint256 precoBilhete;
        uint256 quantidadeBilhete;
        uint256 bilhetesDisponiveis;
        uint256 valorTotal;
        address administrador;
        address ganhador;
        bool rifaFinalizada;
        bool saldoSacado;
    }

    struct TransactionStruct {
        uint256 id;
        address from;
        uint256 value;
        uint256 quantidadeBilhetes;
        uint256 timestamp;
        string tx;
    }

    uint256 public taxaAdministrativa = 10;
    uint256 public ultimaRifaId;
    address public administrador;

    bool private _entrouSacarValorArrecadado = false; // Variável para controlar a execução da função sacarValorArrecadado e para evitar reentrancy attack

    mapping(uint256 => RifaInfo) public rifas;
    mapping(uint256 => Bilhete) public bilhetes;
    mapping(address => uint256) public saldoAdministrativo; //Pool de saldo administrativo para saque do administrador
    TransactionStruct[] public transactions;

    event RifaCriada(uint256 idRifa, uint256 valorPremio);
    event BilheteComprado(address comprador, uint256 idBilhete);
    event TransacaoCriada(uint256 idTransacao);
    event RifaFinalizada(uint256 idRifa, address ganhador);

    event TaxaAdministrativaRecebida(
        address administrador,
        uint256 valorTaxaAdministrativa
    );
    event SaqueRealizado(address destinatario, uint256 valor);

    constructor() {
        administrador = msg.sender;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == administrador,
            unicode"Somente o administrador do contrato pode executar essa função"
        );
        _;
    }

    function criarRifa(
        string memory _nomeRifa,
        string memory _metadataURI,
        uint256 _valorPremio,
        uint256 _precoBilhete,
        uint256 _quantidadeBilhete
    ) external returns (uint256 idRifa) {
        require(
            _valorPremio > 0,
            "O valor total da rifa deve ser maior que zero"
        );
        require(
            _precoBilhete > 0,
            unicode"O preço do bilhete deve ser maior que zero"
        );
        require(
            _quantidadeBilhete > 0,
            "A quantidade de bilhetes deve ser maior que zero"
        );

        ultimaRifaId++;
        idRifa = ultimaRifaId;

        rifas[idRifa] = RifaInfo(
            idRifa,
            _nomeRifa,
            _metadataURI,
            _valorPremio,
            _precoBilhete,
            _quantidadeBilhete,
            _quantidadeBilhete,
            _quantidadeBilhete * _precoBilhete,
            msg.sender,
            address(0),
            false,
            false
        );

        emit RifaCriada(idRifa, _valorPremio);
        return idRifa;
    }

    function comprarBilhete(
        uint256 _idRifa,
        uint256 _qntBilhetes
    ) external payable {
        RifaInfo storage rifa = rifas[_idRifa];
        require(rifa.id != 0, unicode"Rifa não encontrada");
        require(!rifa.rifaFinalizada, unicode"A rifa já foi finalizada");
        require(
            rifa.bilhetesDisponiveis >= _qntBilhetes,
            unicode"Não há bilhetes suficientes disponíveis"
        );
        require(
            msg.value >= rifa.precoBilhete * _qntBilhetes,
            "Valor insuficiente para comprar os bilhetes"
        );

        for (uint256 i = 0; i < _qntBilhetes; i++) {
            uint256 bilheteId = rifa.quantidadeBilhete -
                rifa.bilhetesDisponiveis +
                1;
            bilhetes[bilheteId].dono = msg.sender;
            bilhetes[bilheteId].vendido = true;
            rifa.bilhetesDisponiveis--;
            emit BilheteComprado(msg.sender, bilheteId);
        }

        if (rifa.bilhetesDisponiveis == 0) {
            finalizarRifa(_idRifa);
        }

        ultimaTransacaoId++;

        transactions.push(
            TransactionStruct(
                ultimaTransacaoId,
                msg.sender,
                msg.value,
                _qntBilhetes,
                block.timestamp,
                "0" //tx hash será atualizado posteriormente
            )
        );
        emit TransacaoCriada(ultimaTransacaoId);
    }

    function finalizarRifa(uint256 _idRifa) public {
        RifaInfo storage rifa = rifas[_idRifa];
        require(rifa.id != 0, unicode"Rifa não encontrada");
        require(!rifa.rifaFinalizada, unicode"A rifa já foi finalizada");
        require(
            rifa.bilhetesDisponiveis == 0,
            unicode"A rifa ainda tem bilhetes disponíveis"
        );

        // Lógica para selecionar um ganhador aleatório
        uint256 bilheteGanhador = (uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % rifa.quantidadeBilhete) + 1;
        rifa.ganhador = bilhetes[bilheteGanhador].dono;
        rifa.rifaFinalizada = true;

        // Transfere o valor total da rifa para o ganhador
        payable(rifa.ganhador).transfer(rifa.valorPremio);

        // Calcula a taxa administrativa
        uint256 valorTaxaAdministrativa = (rifa.valorTotal *
            taxaAdministrativa) / 100;

        saldoAdministrativo[administrador] += valorTaxaAdministrativa;

        payable(administrador).transfer(valorTaxaAdministrativa); // Transfere a taxa administrativa para o administrador

        emit RifaFinalizada(_idRifa, rifa.ganhador);
        emit TaxaAdministrativaRecebida(administrador, valorTaxaAdministrativa);
    }

    //dono da rifa pode sacar o valor arrecadado da rifa descontando o valor do premio e a taxa, caso a rifa tenha sido finalizada
    function sacarValorArrecadado(uint256 _idRifa) public {
        RifaInfo storage rifa = rifas[_idRifa];
        require(rifa.id != 0, unicode"Rifa não encontrada");
        require(rifa.rifaFinalizada, unicode"A rifa ainda não foi finalizada");
        require(
            msg.sender == rifa.administrador,
            unicode"Somente o administrador da rifa pode sacar o valor arrecadado"
        );

        // Evita reentrancy attack
        require(
            !_entrouSacarValorArrecadado,
            unicode"Função sacarValorArrecadado em execução"
        );
        _entrouSacarValorArrecadado = true;

        uint256 valorArrecadado = rifa.valorTotal;
        uint256 valorTaxaAdministrativa = (valorArrecadado *
            taxaAdministrativa) / 100;
        uint256 valorLiquido = valorArrecadado -
            rifa.valorPremio -
            valorTaxaAdministrativa;

        payable(msg.sender).transfer(valorLiquido);
        rifa.saldoSacado = true;
        emit SaqueRealizado(msg.sender, valorLiquido);

        _entrouSacarValorArrecadado = false;
    }

    // Função para verificar se o saldo administrativo é válido
    function _validarSaldoAdministrativo(
        address _administrador
    ) private view returns (bool) {
        uint256 saldoCalculado = 0;
        for (uint256 i = 1; i <= ultimaRifaId; i++) {
            RifaInfo storage rifa = rifas[i];
            if (rifa.rifaFinalizada) {
                uint256 valorTaxaAdministrativa = (rifa.valorTotal *
                    taxaAdministrativa) / 100;
                saldoCalculado += valorTaxaAdministrativa;
            }
        }
        return saldoAdministrativo[_administrador] <= saldoCalculado;
    }

    // Função para sacar saldo administrativo
    function sacarSaldoAdministrativo() public onlyAdmin {
        uint256 saldo = saldoAdministrativo[msg.sender];
        require(saldo > 0, "Saldo administrativo insuficiente");

        // Verifica se o saldo administrativo é válido antes de realizar a transferência
        require(
            _validarSaldoAdministrativo(msg.sender),
            unicode"Saldo administrativo inválido"
        );

        saldoAdministrativo[msg.sender] = 0;
        payable(msg.sender).transfer(saldo);
        emit SaqueRealizado(msg.sender, saldo);
    }

    //ajustar a taxa administrativa
    function ajustarTaxaAdministrativa(uint256 _novaTaxa) public onlyAdmin {
        require(
            _novaTaxa >= 0 && _novaTaxa <= 100,
            "A taxa administrativa deve ser um valor entre 0 e 100"
        );

        taxaAdministrativa = _novaTaxa;
    }

    // Função para cancelar a rifa e devolver o valor dos bilhetes aos compradores
    function cancelarRifa(uint256 _idRifa) public {
        RifaInfo storage rifa = rifas[_idRifa];
        require(rifa.id != 0, unicode"Rifa não encontrada");
        require(
            msg.sender == rifa.administrador || msg.sender == administrador,
            unicode"Somente o administrador da rifa pode cancelar a rifa"
        );
        require(
            !rifa.rifaFinalizada,
            unicode"Não é possível cancelar uma rifa finalizada"
        );

        //verifica se a rifa tem bilhetes vendidos, se sim, devolve o valor dos bilhetes aos compradores
        if (rifa.quantidadeBilhete != rifa.bilhetesDisponiveis) {
            for (uint256 i = 1; i <= rifa.quantidadeBilhete; i++) {
                if (bilhetes[i].vendido) {
                    payable(bilhetes[i].dono).transfer(rifa.precoBilhete);
                }
            }
        }

        rifa.rifaFinalizada = true;
    }

    //Função para listar as rifas de um determinado address
    function listarRifas(
        address _address
    ) public view returns (RifaInfo[] memory) {
        uint256 qntRifas = 0;
        for (uint256 i = 1; i <= ultimaRifaId; i++) {
            if (rifas[i].administrador == _address) {
                qntRifas++;
            }
        }

        RifaInfo[] memory rifasUsuario = new RifaInfo[](qntRifas);
        uint256 index = 0;
        for (uint256 i = 1; i <= ultimaRifaId; i++) {
            if (rifas[i].administrador == _address) {
                rifasUsuario[index] = rifas[i];
                index++;
            }
        }

        return rifasUsuario;
    }

    //Função para listar as transações
    function listarTransacoes()
        public
        view
        returns (TransactionStruct[] memory)
    {
        return transactions;
    }

    //Função para atualizar as transações com o ID da transação com hash
    function atualizarTransacao(
        uint256 _idTransacao,
        string memory _tx
    ) public {
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].id == _idTransacao) {
                transactions[i].tx = _tx;
            }
        }
    }

    //Função para listar os bilhetes de um determinado address
    function listarBilhetes(
        address _address
    ) public view returns (Bilhete[] memory) {
        uint256 qntBilhetes = 0;
        for (uint256 i = 1; i <= ultimaRifaId; i++) {
            if (rifas[i].administrador == _address) {
                qntBilhetes += rifas[i].quantidadeBilhete;
            }
        }

        Bilhete[] memory bilhetesUsuario = new Bilhete[](qntBilhetes);
        uint256 index = 0;
        for (uint256 i = 1; i <= ultimaRifaId; i++) {
            if (rifas[i].administrador == _address) {
                for (uint256 j = 1; j <= rifas[i].quantidadeBilhete; j++) {
                    bilhetesUsuario[index] = bilhetes[j];
                    index++;
                }
            }
        }

        return bilhetesUsuario;
    }
}
