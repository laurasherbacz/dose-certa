<?php
namespace Source\Models;

use Source\Core\Model;

class Medicamento 
{
    private ?int $id_medicamento;
    private ?int $id_usuario; 
    private ?string $nome;
    private ?string $dosagem; 
    private ?int $quantidade_por_dose; 
    private ?int $data_inicio; 
    private ?int $duracao_dias; 
    private ?int $valor_pago; 
    private ?int $exige_receita; 
    private ?int $ativo; 

    public function __construct(?int $id_medicamento = null, ?int $id_usuario = null, ?string $nome = null, ?string $dosagem = null, ?int $quantidade_por_dose = null, ?int $data_inicio = null, ?int $duracao_dias = null, ?int $valor_pago = null, ?int $exige_receita = null, ?int $ativo = null) 
    {
        $this->id_medicamento = $id_medicamento;
        $this->id_usuario = $id_usuario;
        $this->nome = $nome;
        $this->dosagem = $dosagem;
        $this->quantidade_por_dose = $quantidade_por_dose;
        $this->data_inicio = $data_inicio;
        $this->duracao_dias = $duracao_dias;
        $this->valor_pago = $valor_pago;
        $this->exige_receita = $exige_receita;
        $this->ativo = $ativo;
    }

    public function getIdMedicamento(): int 
    {
        return $this->id_medicamento; 
    }

    public function getIdUsuario(): int 
    {
        return $this->id_usuario; 
    }

    public function getNome(): string 
    {
        return $this->nome; 
    }

    public function getDosagem(): string 
    {
        return $this->dosagem; 
    }

    public function getQuantidadePorDose(): int 
    {
        return $this->quantidade_por_dose; 
    }

    public function getDataInicio(): int 
    {
        return $this->data_inicio; 
    }

    public function getDuracaoDias(): int 
    {
        return $this->duracao_dias; 
    }

    public function getValorPago(): int 
    {
        return $this->valor_pago; 
    }

    public function getExigeReceita(): int 
    {
        return $this->exige_receita; 
    }

    public function getAtivo(): int 
    {
        return $this->ativo; 
    }

    public function setIdMedicamento(int $id_medicamento): void 
    {
        $this->id_medicamento = $id_medicamento; 
    }

    public function setIdUsuario(int $id_usuario): void 
    {
        $this->id_usuario = $id_usuario; 
    }

    public function setNome(string $nome): void 
    {
        $this->nome = $nome; 
    }

    public function setDosagem(string $dosagem): void 
    {
        $this->dosagem = $dosagem; 
    }

    public function setQuantidadePorDose(int $quantidade_por_dose): void 
    {
        $this->quantidade_por_dose = $quantidade_por_dose; 
    }

    public function setDataInicio(int $data_inicio): void 
    {
        $this->data_inicio = $data_inicio; 
    }

    public function setDuracaoDias(int $duracao_dias): void 
    {
        $this->duracao_dias = $duracao_dias; 
    }

    public function setValorPago(int $valor_pago): void 
    {
        $this->valor_pago = $valor_pago; 
    }

    public function setExigeReceita(int $exige_receita): void 
    {
        $this->exige_receita = $exige_receita; 
    }

    public function setAtivo(int $ativo): void 
    {
        $this->ativo = $ativo; 
    }

    public function listAll(): array 
    {
        $query = "SELECT * FROM medicamento .*, usuario.nome AS nome_usuario FROM medicamento 
                  INNER JOIN usuario ON medicamento.id_usuario = usuario.id_usuario";
        $stmt = Connect::getInstance()->prepare($query);
        return $stmt->fetchAll(); 
    }

    public function listById(int $id): object | false
    {
        $query = "SELECT * FROM medicamentos WHERE id_medicamento = :id";
        $stmt = Connect::getInstance()->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch();
    }

    public function insert(): bool 
    {
        $query = "INSERT INTO medicamento(id_usuario, nome, dosagem, quantidade_por_dose, data_inicio, duracao_dias, valor_pago, exige_receita, ativo) 
                  VALUES (:id_usuario, :nome, :dosagem, :quantidade_por_dose, :data_inicio, :duracao_dias, :valor_pago, :exige_receita, :ativo)";

        $stmt = Connect::getInstance()->prepare($query);

        $stmt->bindParam(':id_usuario', $this->id_usuario);
        $stmt->bindParam(':nome', $this->nome);
        $stmt->bindParam(':dosagem', $this->dosagem);
        $stmt->bindParam(':quantidade_por_dose', $this->quantidade_por_dose);
        $stmt->bindParam(':data_inicio', $this->data_inicio);
        $stmt->bindParam(':duracao_dias', $this->duracao_dias);
        $stmt->bindParam(':valor_pago', $this->valor_pago);
        $stmt->bindParam(':exige_receita', $this->exige_receita);
        $stmt->bindParam(':ativo', $this->ativo);

        if(!$stmt->execute()){
            return false;
        }

        $this->id_medicamento = Connect::getInstance()->lastInsertId();
        return true;
    }
        public function update(array $data): bool
        {
            $query = "UPDATE medicamento SET nome = :nome, dosagem = :dosagem, quantidade_por_dose = :quantidade_por_dose, data_inicio = :data_inicio, duracao_dias = :duracao_dias, valor_pago = :valor_pago, exige_receita = :exige_receita, ativo = :ativo WHERE id_medicamento = :id_medicamento";
            $stmt = Connect::getInstance()->prepare($query);

            $stmt->bindParam(':id_medicamento', $data['id_medicamento']);
            $stmt->bindParam(':nome', $data['nome']);   
            $stmt->bindParam(':dosagem', $data['dosagem']);
            $stmt->bindParam(':quantidade_por_dose', $data['quantidade_por_dose']);
            $stmt->bindParam(':data_inicio', $data['data_inicio']);
            $stmt->bindParam(':duracao_dias', $data['duracao_dias']);
            $stmt->bindParam(':valor_pago', $data['valor_pago']);
            $stmt->bindParam(':exige_receita', $data['exige_receita']);
            $stmt->bindParam(':ativo', $data['ativo']);

            return $stmt->execute();
        }

        public function delete(int $id): bool
        {
            $query = "UPDATE medicamento SET ativo = 0 WHERE id_medicamento = :id_medicamento";
            $stmt = Connect::getInstance()->prepare($query);
            $stmt->bindParam(':id_medicamento', $id);
            return $stmt->execute();
        }
    }

