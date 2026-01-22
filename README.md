<!-- README.md (HTML simples) -->

<div align="center">
  <h1>MRI Garage</h1>
  <p><strong>Sistema completo de garagens para servidores FiveM (MRI Qbox/QBX)</strong></p>
  <p>
    UI moderna e responsiva • Garagens públicas/privadas • Retirada com status do veículo • Builder/Admin • Transferência de veículos
  </p>

  <p>
    <a href="#visao-geral">Visão geral</a> •
    <a href="#recursos">Recursos</a> •
    <a href="#requisitos">Requisitos</a> •
    <a href="#instalacao">Instalação</a> •
    <a href="#configuracao">Configuração</a> •
    <a href="#como-usar">Como usar</a> •
    <a href="#transferencia">Transferência</a> •
    <a href="#builderadmin">Builder/Admin</a> •
    <a href="#banco-de-dados">Banco de dados</a> •
    <a href="#troubleshooting">Troubleshooting</a>
  </p>
</div>

<hr/>

<h2 id="visao-geral">Visão geral</h2>
<p>
  <strong>MRI Garage</strong> é um script de garagem para FiveM focado em base <strong>MRI Qbox/QBX</strong>, projetado para uso por
  <strong>players comuns</strong> e também para <strong>admins/builders</strong> que desejam criar e gerenciar garagens in-game.
</p>
<p>
  Ele traz uma <strong>UI elegante</strong>, listagem de veículos do jogador, retirada e armazenamento, além de ferramentas para
  <strong>definir spawn de saída</strong>, atualizar nome/posição e transferir veículos para outros jogadores.
</p>

<hr/>

<h2 id="recursos">Recursos</h2>

<h3>✅ UI moderna</h3>
<ul>
  <li>Painel limpo e responsivo, com busca de veículos.</li>
  <li>Exibição de informações do veículo com visual organizado.</li>
  <li>Modal interno profissional para transferência (sem <code>prompt()</code> do navegador).</li>
</ul>

<h3>🚗 Gerenciamento de veículos</h3>
<ul>
  <li><strong>Listagem</strong> de veículos do jogador (consulta ao banco <code>player_vehicles</code>).</li>
  <li><strong>Retirar veículo</strong> com spawn configurado pela garagem.</li>
  <li><strong>Guardar veículo atual</strong> (Store Current).</li>
  <li><strong>Status visual</strong> (quando disponível): gasolina/bateria e condição/danos.</li>
  <li>Compatibilidade com diferentes esquemas de colunas (ex.: <code>mods</code>, <code>stored/state</code>) quando aplicável.</li>
</ul>

<h3>🔑 Integração com chaves</h3>
<ul>
  <li>Ao retirar o veículo, o script tenta entregar a chave automaticamente.</li>
  <li>Compatível com o ecossistema MRI/Qbox conforme sua base (integrações podem variar por cidade).</li>
</ul>

<h3>🅿️ Sistema de garagens (públicas e personalizadas)</h3>
<ul>
  <li>Garagens com nome, localização e spawn de saída.</li>
  <li>Opção de <strong>definir o spawn de saída</strong> (onde o veículo nasce ao retirar).</li>
  <li>Posição da garagem pode ser ajustada in-game.</li>
</ul>

<h3>🔁 Transferência de veículos</h3>
<ul>
  <li>Transferir veículo para outro jogador por <strong>ID do player (server id)</strong> ou por <strong>CitizenID</strong>.</li>
  <li>Campo de <strong>preço opcional</strong> (caso sua lógica de cidade utilize cobrança).</li>
  <li>Fluxo feito por modal na UI (mais seguro e profissional).</li>
</ul>

<hr/>

<h2 id="requisitos">Requisitos</h2>
<ul>
  <li><strong>FiveM</strong> (FXServer) atualizado</li>
  <li><strong>ox_lib</strong></li>
  <li><strong>oxmysql</strong></li>
  <li>Base compatível com <strong>MRI Qbox/QBX</strong></li>
</ul>

<hr/>

<h2 id="instalacao">Instalação</h2>
<ol>
  <li>Coloque a pasta do resource em <code>resources/[mri]/mri_garage</code> (ou onde preferir).</li>
  <li>Garanta que as dependências iniciem antes do script:</li>
</ol>

<pre>
ensure ox_lib
ensure oxmysql
ensure mri_garage
</pre>

<ol start="3">
  <li>Reinicie o servidor ou use <code>restart mri_garage</code>.</li>
</ol>

<hr/>

<h2 id="configuracao">Configuração</h2>
<p>
  As configurações ficam normalmente em <code>shared/config.lua</code>.
  Ajuste conforme sua cidade (nomes de comandos, permissões e integrações).
</p>

<h3>Permissão por ACE (Admin/Builder)</h3>
<p>
  Se sua cidade libera permissões por ACE, use algo como:
</p>

<pre>
add_ace group.admin "command.garagebuilder" allow
add_ace group.superadmin "command.garagebuilder" allow
</pre>

<p>
  Depois, no config, mantenha as permissões esperadas:
</p>

<pre>
Config.UseAceForBuilder = true

Config.BuilderAcePermissions = {
  "group.admin",
  "group.superadmin",
  "command.garagebuilder"
}
</pre>

<hr/>

<h2 id="como-usar">Como usar</h2>

<h3>Abrir a garagem</h3>
<ul>
  <li>Vá até a área marcada e use a tecla indicada (ex.: <strong>E</strong>).</li>
  <li>A UI abrirá listando seus veículos.</li>
</ul>

<h3>Retirar veículo</h3>
<ul>
  <li>Selecione o veículo na lista.</li>
  <li>Clique em <strong>RETIRAR</strong>.</li>
  <li>O veículo será spawnado no <strong>spawn configurado</strong> da garagem.</li>
  <li>O script tenta entregar a <strong>chave</strong> automaticamente ao retirar.</li>
</ul>

<h3>Guardar veículo atual</h3>
<ul>
  <li>Com o veículo próximo/atual, use <strong>Store Current</strong>.</li>
  <li>O veículo é armazenado e o estado no banco é atualizado conforme sua base.</li>
</ul>

<hr/>

<h2 id="transferencia">Transferência</h2>
<p>
  O botão <strong>TRANSFER</strong> abre um modal interno (sem travar a tela).
</p>
<ul>
  <li><strong>ID do player (server)</strong>: recomendado. É o número do player no servidor.</li>
  <li><strong>CitizenID</strong>: opcional, caso você saiba o identificador do alvo.</li>
  <li><strong>Preço</strong>: opcional (depende de como sua cidade cobra transferências).</li>
</ul>

<p>
  Após confirmar, o script processa a troca de dono do veículo no banco.
</p>

<hr/>

<h2 id="builderadmin">Builder/Admin</h2>

<h3>Gerenciar garagens</h3>
<p>Para usuários com permissão (ACE), o painel de gerenciamento permite:</p>
<ul>
  <li><strong>Atualizar nome</strong> da garagem.</li>
  <li><strong>Atualizar posição</strong> (setar a garagem no local atual).</li>
  <li><strong>Definir spawn de saída</strong> (onde os veículos devem nascer ao retirar).</li>
  <li><strong>Deletar garagem</strong>.</li>
</ul>

<p>
  <strong>Spawn estrito:</strong> o script pode ser configurado para usar apenas o spawn definido (1 ponto fixo),
  garantindo que o veículo sempre saia exatamente onde você configurou.
</p>

<hr/>

<h2 id="banco-de-dados">Banco de dados</h2>

<h3>Tabela de veículos</h3>
<p>
  O script utiliza a tabela <code>player_vehicles</code> para listar/retirar/guardar veículos.
  Dependendo da sua base, o schema pode variar (ex.: <code>mods</code> separado, flags <code>stored</code> ou <code>state</code> etc.).
</p>

<h3>Tabela de garagens</h3>
<p>
  O resource também mantém uma tabela própria para armazenar dados das garagens (nome, coords, spawn).
</p>

<p>
  <em>Obs.:</em> Se sua base tiver um schema custom, adapte os nomes de colunas no server conforme necessário.
</p>

<hr/>

<h2 id="troubleshooting">Troubleshooting</h2>

<h3>1) “Não carrega veículos” / lista vazia</h3>
<ul>
  <li>Confirme que <code>oxmysql</code> está iniciado antes do script.</li>
  <li>Confirme o nome da tabela: <code>player_vehicles</code>.</li>
  <li>Verifique se o identificador do dono é compatível (geralmente <code>citizenid</code>).</li>
</ul>

<h3>2) Veículo não sai no local configurado</h3>
<ul>
  <li>Use a opção <strong>Definir spawn de saída</strong> e teste retirando novamente.</li>
  <li>Evite manter múltiplos spawns se sua regra é “apenas 1 spawn fixo”.</li>
</ul>

<h3>3) Veículo sai sem chave</h3>
<ul>
  <li>Confirme que seu resource de chaves está iniciado antes do <code>mri_garage</code>.</li>
  <li>Se sua cidade usa um sistema de keys custom, ajuste a chamada de evento/export no client/server do <code>mri_garage</code>.</li>
</ul>

<h3>4) UI travando/elemento aparecendo sozinho</h3>
<ul>
  <li>Isso geralmente é CSS/estado inicial. Garanta que elementos “hidden” realmente iniciem como <code>display:none</code>.</li>
  <li>Evite uso de <code>prompt()</code> do browser e prefira modal interno (já incluso).</li>
</ul>

<hr/>

<h2 id="licenca">Licença</h2>
<p>
  Defina aqui sua licença (MIT, GPL, proprietária, etc).
</p>

<hr/>

<div align="center">
  <p>
    <strong>Feito para cidades MRI Qbox/QBX</strong><br/>
    Se você customizou seu schema ou keys, ajuste os handlers e eventos conforme sua base.
  </p>
</div>
