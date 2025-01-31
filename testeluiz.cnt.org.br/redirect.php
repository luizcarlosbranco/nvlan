<?php
// Inclui o arquivo de configuração
require_once 'config.conf';

ini_set('display_errors', 1);
error_reporting(E_ALL);

// Conecta ao banco de dados
$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Verifica a conexão
if ($mysqli->connect_error) {
    die('Erro ao conectar ao banco de dados: ' . $mysqli->connect_error);
}

// Captura a nome da URL
$nome = isset($_GET['rota']) ? $mysqli->real_escape_string($_GET['rota']) : '';

// Verifica se a rota foi informada
if (empty($nome)) {
    die('Erro: Nenhuma rota especificada.');
}

// Consulta a rota no banco de dados
$stmt = $mysqli->prepare('SELECT r.id AS rota_id, r.nome AS rota_nome, r.created_at AS rota_created_at, url_destino AS url_destino, r.enabled AS enabled, r.created_at AS created_at, p.prazo AS plano_validade, p.nome AS plano_nome, p.prazo AS plano_prazo, u.email AS user_email FROM rotas r INNER JOIN usuarios u ON r.id_usuario = u.id INNER JOIN planos p ON p.id = u.plano WHERE r.nome = ?');
$stmt->bind_param('s', $nome);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    die('Erro: Rota não encontrada.');
}

$rotaData = $result->fetch_assoc();

// Verifica a rota
if ($rotaData['enabled'] === 0) {
    die('Erro: Rota desativada.');
}

// Calcula a validade do plano
$dataCriacao = new DateTime($rotaData['created_at']);
$validadePlano = (int)$rotaData['plano_validade'];
$dataExpiracao = $dataCriacao->modify("+$validadePlano days");
$dataAtual = new DateTime();

if ($dataAtual > $dataExpiracao) {
    die('Erro: O prazo desta rota expirou.');
}

// Captura o IP do cliente
$clientIp = $_SERVER['REMOTE_ADDR'] ?? 'Desconhecido';
$xRealIp = $_SERVER['HTTP_X_REAL_IP'] ?? 'Desconhecido';

// Registra o acesso no log
$logStmt = $mysqli->prepare('INSERT INTO logs_redirect (usuario_email, rota_nome, rota_created_at, plano_nome, plano_prazo, rota_id, data_acesso, redirect_to, remote_addr, real_ip) VALUES (?, ?, ?, ?, ?, ?, NOW(), ?, ?, ?)');
$logStmt->bind_param(
    'ssssiisss', // Ajustado para garantir que "plano_nome" seja tratado como string
    $rotaData['user_email'],
    $rotaData['rota_nome'],
    $rotaData['rota_created_at'],
    $rotaData['plano_nome'], // Agora corretamente tratado como string
    $rotaData['plano_prazo'], // Certifique-se de que "plano_prazo" seja inteiro
    $rotaData['rota_id'], // ID da rota, inteiro
    $rotaData['url_destino'],
    $clientIp,
    $xRealIp
);$logStmt->execute();
$logStmt->close();

// Redireciona para a URL associada
header('Location: ' . $rotaData['url_destino']);
exit;
?>

