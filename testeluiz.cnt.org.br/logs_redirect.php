<?php
session_start();

ini_set('display_errors', 1);
error_reporting(E_ALL);

// Verifica se o usuário está logado e se é o administrador
if (!isset($_SESSION['user_id']) || $_SESSION['email'] != 'admin@admin') {
    // Se o usuário não estiver logado ou não for o admin, redireciona para o login
    header("Location: login.php");
    exit();
}

require_once 'config.conf';  // Conexão com o banco de dados

// Conectar ao banco de dados
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($conn->connect_error) {
    die("Conexão falhou: " . $conn->connect_error);
}

// Função para exibir os logs
function exibirLogs($conn) {
//    $sql = "SELECT logs.*, usuarios.email AS usuario_email, planos.nome AS plano_nome, rotas.nome AS rota_nome 
//           FROM logs 
//           LEFT JOIN usuarios ON logs.id_usuario = usuarios.id
//            LEFT JOIN planos ON logs.id_plano = planos.id
//            LEFT JOIN rotas ON logs.id_rota = rotas.id
//            ORDER BY logs.data DESC";
    $sql = "SELECT data_acesso, id_rota, redirected_to, remote_addr, real_ip FROM logs_redirect";

    $sql = "SELECT  l.data_acesso AS data_acesso, l.id_rota AS id_rota, l.redirected_to AS redirected_to, l.remote_addr AS remote_addr, l.real_ipr AS real_ipr
	    FROM logs_redirect l
            INNET JOIN
            INNER JOIN usuarios u ON r.id_usuario = u.id 
            INNER JOIN planos p ON p.id = u.plano";
//            WHERE r.rota = ?";

	FROM rotas r
	INNER JOIN usuarios u ON r.id_usuario = u.id
	INNER JOIN planos p ON p.id = u.plano


    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
	    echo "<tr>";
	    echo "<td>" . $row['data_acesso'] . "</td>";
	    echo "<td>" . $row['data_acesso'] . "</td>";
	    echo "<td>" . $row['data_acesso'] . "</td>";
	    echo "<td>" . $row['data_acesso'] . "</td>";
            echo "<td>" . $row['data_acesso'] . "</td>";
            echo "<td>" . htmlspecialchars($row['id_rota']) . "</td>";
            echo "<td>" . htmlspecialchars($row['redirected_to']) . "</td>";
            echo "<td>" . htmlspecialchars($row['remote_addr']) . "</td>";
            echo "<td>" . htmlspecialchars($row['real_ip']) . "</td>";
            echo "</tr>";
        }
    } else {
        echo "<tr><td colspan='5'>Nenhum log encontrado</td></tr>";
    }
}

?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Logs de Auditoria - Painel Administrativo</title>
</head>
<body>

<h1>Logs de Auditoria</h1>

<!-- Botão para voltar para o painel administrativo -->
<a href="admin_page.php"><button>Voltar para o Painel Administrativo</button></a>

<h2>Histórico de Ações</h2>
<table border="1">
    <thead>
	<tr>
            <th>Nome da Rota</th>
	    <th>Dono da Rota</th>
	    <th>data_de_criacao</th>
            <th>Nome do Plano</th>
	    <th>data_acesso</th>
            <th>id_rota</th>
            <th>redirected_to</th>
            <th>remote_addr</th>
            <th>real_ip</th>
        </tr>
    </thead>
    <tbody>
        <?php exibirLogs($conn); ?>
    </tbody>
</table>

</body>
</html>

<?php
$conn->close();
?>

