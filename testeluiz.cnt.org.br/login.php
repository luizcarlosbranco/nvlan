<?php
session_start(); // Inicia a sessão para verificar o login

// Configurações do banco de dados
require_once 'config.conf'; // Inclua o arquivo de configuração com os dados do banco

// Se o usuário já estiver logado, redireciona para o dashboard
if (isset($_SESSION['user_id'])) {
    // Verifica se o usuário é o administrador ou não e redireciona para o dashboard adequado
    if ($_SESSION['email'] == 'admin@admin') {
        header("Location: admin_page.php"); // Redireciona para o painel do admin
    } else {
        header("Location: dashboard.php"); // Redireciona para o painel do usuário
    }
    exit();
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Recebe os dados do formulário
    $email = $_POST['email'];
    $senha = $_POST['senha'];

    // Conexão com o banco de dados
    try {
        $pdo = new PDO("mysql:host=".DB_HOST.";dbname=".DB_NAME, DB_USER, DB_PASS);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Prepara a consulta para buscar o usuário
        $stmt = $pdo->prepare("SELECT id, email, senha, enabled FROM usuarios WHERE email = :email LIMIT 1");
        $stmt->bindParam(':email', $email);
        $stmt->execute();

        // Verifica se o usuário existe
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user && password_verify($senha, $user['senha'])) {  // Verifica a senha com password_verify
            if ($user['enabled'] == 1) { // Verifica se a conta esta ativa
                // Login bem-sucedido, define as variáveis de sessão
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['email'] = $user['email'];

                // Verifica se o usuário é o admin ou não e redireciona adequadamente
                if ($user['email'] == 'admin@admin') {
                    header("Location: admin_page.php"); // Redireciona para o painel de admin
                } else {
                    header("Location: dashboard.php"); // Redireciona para o painel do usuário comum
                }
                exit();
            } else {
                // Se a conta estiver desativada
                $erro = "Sua conta está desativada. Entre em contato com o administrador.";
            }
        } else {
            // Se as credenciais não forem válidas
            $erro = "Credenciais inválidas. Verifique seu e-mail e senha.";
        }

    } catch (PDOException $e) {
        // Em caso de erro na conexão ou consulta
        $erro = "Erro na conexão com o banco de dados. Tente novamente mais tarde.";
    }
}
?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Sistema</title>
</head>
<body>

    <h2>Login</h2>

    <!-- Se houver erro, exibe a mensagem -->
    <?php if (isset($erro)) { echo "<p style='color: red;'>$erro</p>"; } ?>

    <form action="login.php" method="POST">
        <label for="email">E-mail:</label><br>
        <input type="email" id="email" name="email" required><br><br>

        <label for="senha">Senha:</label><br>
        <input type="password" id="senha" name="senha" required><br><br>

        <button type="submit">Entrar</button>
    </form>

    <p>Não tem uma conta? <a href="cadastro.php">Cadastre-se aqui</a></p>

</body>
</html>

