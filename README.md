# Dose Certa - Sistema para Controle de Medicamentos

Front-end (layout) do sistema **Dose Certa**, desenvolvido no curso de Desenvolvimento Front-end (Bolsa Futuro Digital).

## Visão geral
Ajuda pessoas que usam medicamentos regularmente a organizar seus tratamentos: cadastro de medicamentos, dosagens, horários e duração, lembretes, controle de estoque, gastos e renovação de receitas, com interface simples e acessível e possibilidade de acompanhamento por familiares ou cuidadores.

## Público-alvo
- **Adultos/jovens** com tratamentos contínuos.
- **Idosos**, com interface acessível e acompanhamento por familiares ou cuidadores autorizados.

## Funcionalidades previstas
Cadastrar, editar e excluir medicamentos; visualizar lembretes; registrar doses; controlar estoque, gastos e receitas; compartilhar acesso; consultar histórico.

## Estrutura do projeto
- **Área pública:** `index.html` (Home), `sobre.html`, `contato.html`, `faq.html`, `cadastro.html`, `login.html`
- **Área da aplicação** (`app/`): painel, medicamentos, receitas, gastos (CRUDs) e perfil
- **Área administrativa** (`admin/`): dashboard, catálogo de medicamentos (CRUD), gestão de FAQs (CRUD) e perfil do administrador
- `css/style.css` (tema verde) e `js/main.js` (validação de formulários)

## Tecnologias
HTML5, CSS3, JavaScript e Bootstrap 5.3 (via CDN).

## Como executar
Baixe o projeto e abra `index.html` no navegador (é necessária conexão com a internet para carregar o Bootstrap).

> Esta etapa contém apenas o layout (front-end), sem back-end: os dados exibidos são exemplos.
