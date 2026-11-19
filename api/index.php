<?php

error_reporting(E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED);
// timezone para São Paulo América
date_default_timezone_set('America/Sao_Paulo');

ob_start();

require  __DIR__ . "/vendor/autoload.php";

// os headers abaixo são necessários para permitir o acesso a API por clientes externos ao domínio
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header('Access-Control-Allow-Credentials: true'); // Permitir credenciais

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

use CoffeeCode\Router\Router;
// localhost/acme-3am/api
$route = new Router(url("api"),":");

$route->namespace("Source\Controller");
// localhost/acme-3am/api/hello
$route->get("/hello", "Api:hello");
$route->get("/products", "Products:productsList");
$route->get("/products/menu", "Products:productsMenu");
$route->get("/products/list/{productId}","Products:productsListById");
$route->put("/products/{productId}","Products:update");
$route->delete("/products/{productId}","Products:delete");
$route->post("/products", "Products:insert");
$route->get("/products-categories/list", "ProductsCategories:productsCategoriesList");


$route->get("/users/list", "Users:usersList");
$route->post("/register","Users:register"); // Registrar usuário comum
$route->post("/login","Users:auth"); // login de usuário comum
$route->put("/update","Users:update"); // update de usuário comum
$route->post("/register-admin","Users:registerAdmin"); // Registrar usuário admin NÃO IMPLEMENTADO
$route->post("/login-admin","Users:authAdmin"); // login de usuário admin
$route->put("/update-admin","Users:updateAdmin"); // update de usuário admin


/* ============== FAQS ================*/
$route->get("/faqs-categories/list", "FaqsCategories:faqsCategoryList");
$route->get("/faqs-categories/list/{categoryId}", "FaqsCategories:faqsCategoryListById");

$route->get("/faqs/list", "Faqs:faqsListAll");
$route->get("/faqs/list/{faqId}", "Faqs:faqsListById");

$route->post("/faqs-categories/create", "FaqsCategories:faqsCategoriesCreate");
$route->post("/faqs/insert", "Faqs:faqInsert");

$route->put("/faqs/update/{faqId}", "Faqs:faqUpdate");
$route->put("/faqs-categories/update/{categoryId}", "FaqsCategories:faqCategoryUpdate");

$route->delete("/faqs/{faqId}", "Faqs:faqDelete");
$route->delete("/faqs-categories/{categoryId}", "FaqsCategories:faqCategoryDelete");

// Orders
$route->get("/orders", "Orders:ordersList");
$route->get("/orders/list/{orderId}", "Orders:ordersListById");
$route->post("/orders", "Orders:insert");
$route->put("/orders/{orderId}", "Orders:update");
$route->delete("/orders/{orderId}", "Orders:delete");

// OrdersItems
$route->get("/orders-items", "OrdersItems:ordersItemsList");
$route->get("/orders-items/list/{orderItemId}", "OrdersItems:ordersItemsListById");
$route->post("/orders-items", "OrdersItems:insert");
$route->put("/orders-items/{orderItemId}", "OrdersItems:update");
$route->delete("/orders-items/{orderItemId}", "OrdersItems:delete");
// --------------- Fim - Exercícios - Desafios ---------------

$route->dispatch(); 

/** ERROR REDIRECT */
if ($route->error()) {
    header('Content-Type: application/json; charset=UTF-8');
    //http_response_code(404);

    echo json_encode([
        "code" => 404,
        "status" => "not_found",
        "message" => "URL não encontrada"
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

}

ob_end_flush(); 