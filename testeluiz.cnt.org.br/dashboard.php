<?php
session_start();
require_once 'config.conf';

ini_set('display_errors', 1);
error_reporting(E_ALL);

// Verifica a sessão e o timeout
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity'] > TIMEOUT)) {
    session_unset();
    session_destroy();
    header('Location: login.php?timeout=1');
    exit;
}

$_SESSION['last_activity'] = time();

$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

if ($mysqli->connect_error) {
    die('Erro ao conectar ao banco de dados: ' . $mysqli->connect_error);
}

$user_id = $_SESSION['user_id'];

// Criação de rota
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['new_route'])) {
    $nome = trim($_POST['nome']);
    $url = trim($_POST['url']);

    if (!empty($nome) && !empty($url)) {
        $stmt = $mysqli->prepare('INSERT INTO rotas (nome, id_usuario, created_at, enabled, url_destino) VALUES (?, ?, NOW(), 1, ?)');
        $stmt->bind_param('sis', $nome, $user_id, $url);

        if ($stmt->execute()) {
            $mensagem = 'Rota criada com sucesso.';
        } else {
            $erro = 'Erro ao criar a rota. Verifique se o nome da rota já está em uso.';
        }
    } else {
        $erro = 'Todos os campos são obrigatórios.';
    }
}

// Verificar qual ação o administrador quer executar
$action = isset($_GET['action']) ? $_GET['action'] : 'dashboard';

//Fazer Logoff
if ($action === 'logoff') {
    session_unset(); // Remove todas as variáveis da sessão
    session_destroy(); // Destroi a sessão
    header("Location: login.php"); // Redireciona para a página de login
    exit();
}

// Listagem de rotas
$stmt = $mysqli->prepare('SELECT id, nome, url_destino, created_at FROM rotas WHERE id_usuario = ? AND enabled = 1');
$stmt->bind_param('i', $user_id);
$stmt->execute();
$result = $stmt->get_result();

$rotas = [];
while ($row = $result->fetch_assoc()) {
    $rotas[] = $row;
}
?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Painel do Usuário</title>
</head>
<body>
<!-- Menu de navegação -->

    <h1>Bem-vindo ao seu painel!</h1>

    <a href="dashboard.php?action=logoff"><button>Sair</button></a>

    <?php if (isset($mensagem)): ?>
        <p style="color: green;"><?= htmlspecialchars($mensagem) ?></p>
    <?php elseif (isset($erro)): ?>
        <p style="color: red;"><?= htmlspecialchars($erro) ?></p>
    <?php endif; ?>

    <h2>Criar Nova Rota</h2>
    <form method="post" action="">
        <label for="rota">Nome da Rota:</label>
        <input type="text" name="nome" id="nome" required>
        <br>
        <label for="url">URL de Destino:</label>
        <input type="url" name="url" id="url" required>
        <br>
        <button type="submit" name="new_route">Criar Rota</button>
    </form>

    <h2>Suas Rotas</h2>
    <?php if (!empty($rotas)): ?>
        <table border="1">
            <thead>
                <tr>
                    <th>Nome da Rota</th>
                    <th>URL de Destino</th>
                    <th>Data de Criação</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($rotas as $rota): ?>
                    <tr>
                        <td><?= htmlspecialchars($rota['nome']) ?></td>
                        <td><?= htmlspecialchars($rota['url_destino']) ?></td>
                        <td><?= htmlspecialchars($rota['created_at']) ?></td>
                        <td>
                            <a href="edit_route.php?id=<?= $rota['id'] ?>">Editar</a> |
                            <a href="delete_route.php?id=<?= $rota['id'] ?>" onclick="return confirm('Tem certeza que deseja excluir esta rota?');">Excluir</a>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php else: ?>
        <p>Você ainda não possui rotas criadas.</p>
    <?php endif; ?>
</body>
</html>

