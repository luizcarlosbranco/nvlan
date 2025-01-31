<?php
// Inclui o arquivo de configuração
require_once 'config.conf';

ini_set('display_errors', 1);
error_reporting(E_ALL);

// Verifica se o sistema já está instalado
if (defined('FIRSTINSTALL') && FIRSTINSTALL === 0) {
    die('Erro: O sistema já está instalado.');
}

// Inicializa variáveis
$error = '';
$success = '';

// Verifica se o formulário foi enviado
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dbHost = $_POST['db_host'];
    $dbUser = $_POST['db_user'];
    $dbPass = $_POST['db_pass'];
    $dbName = $_POST['db_name'];
    $adminPass = $_POST['admin_pass'];

    // Tenta conectar ao banco de dados
    $mysqli = new mysqli($dbHost, $dbUser, $dbPass);

    if ($mysqli->connect_error) {
        $error = 'Erro ao conectar ao banco de dados: ' . $mysqli->connect_error;
    } else {
        // Cria o banco de dados
        if ($mysqli->query("CREATE DATABASE IF NOT EXISTS `$dbName`")) {
            $mysqli->select_db($dbName);

            // Executa o script SQL para criar tabelas
            $sql = file_get_contents('db.sql');
            if ($mysqli->multi_query($sql)) {
                do {
                    $mysqli->next_result();
                } while ($mysqli->more_results());
            }

            // Insere o administrador
            $adminEmail = 'admin@admin';
            $adminPassHash = password_hash($adminPass, PASSWORD_BCRYPT);
            $stmt = $mysqli->prepare('INSERT INTO usuarios (email, senha, enabled, plano) VALUES (?, ?, ?, ?)');
            $enabled = 1;
            $plano = 1; // ID do plano padrão
            $stmt->bind_param('sssi', $adminEmail, $adminPassHash, $enabled, $plano);
            $stmt->execute();

            // Atualiza o arquivo de configuração
            $configData = <<<CONFIG
<?php
define('DB_HOST', '$dbHost');
define('DB_USER', '$dbUser');
define('DB_PASS', '$dbPass');
define('DB_NAME', '$dbName');
define('FIRSTINSTALL', 0);
define('TIMEOUT', 30);
define('SMTP', 'smtp.blob.com');
define('SITE_NAME', 'Blob System');
CONFIG;

            file_put_contents('config.conf', $configData);

            $success = 'Configuração concluída com sucesso!';
        } else {
            $error = 'Erro ao criar o banco de dados.';
        }
    }

    $mysqli->close();
}
?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Instalação</title>
</head>
<body>
    <h1>Instalação do Sistema</h1>
    <?php if ($error): ?>
        <p style="color: red;"><?= htmlspecialchars($error) ?></p>
    <?php elseif ($success): ?>
        <p style="color: green;"><?= htmlspecialchars($success) ?></p>
        <a href="login.php">Ir para o login</a>
    <?php else: ?>
        <form method="POST">
            <label>Host do Banco de Dados:</label>
            <input type="text" name="db_host" required><br>
            <label>Usuário do Banco de Dados:</label>
            <input type="text" name="db_user" required><br>
            <label>Senha do Banco de Dados:</label>
            <input type="password" name="db_pass"><br>
            <label>Nome do Banco de Dados:</label>
            <input type="text" name="db_name" required><br>
            <label>Senha do Administrador:</label>
            <input type="password" name="admin_pass" required><br>
            <button type="submit">Avançar</button>
        </form>
    <?php endif; ?>
</body>
</html>

