(function () {
  var packs = {
    en: {
      "meta.title": "Workshop [black-ops]",
      "meta.description": "A workshop to set up [black-ops] on a modest laptop: LocalAI, agents, MCPs, a first run, and a look at the metrics.",
      "skip": "Skip to content",
      "lang.aria": "Language",
      "nav.aria": "Workshop",
      "brand.alt": "Three-headed hydra mark",
      "brand.name": "Workshop",
      "brand.tag": "[black-ops]",
      "nav.llm": "LocalAI",
      "nav.agent": "Agents",
      "nav.mcp": "MCPs",
      "nav.lab": "Labs",
      "nav.qa": "QA",
      "home.kicker": "Your test machine",
      "home.title": "This works on a modest laptop.",
      "home.lede": "A server is not required. Set up on this test machine: a 4 GB graphics card and 15 GB of RAM. If the machine looks like this, the workshop runs. The system is Ubuntu 26.04.1 LTS.",
      "home.table": "Hardware of the modest laptop",
      "spec.part": "Part",
      "spec.value": "What it has",
      "spec.os": "System",
      "spec.os.v": "Ubuntu 26.04.1 LTS (Resolute Raccoon)",
      "spec.cpu": "CPU",
      "spec.cpu.v": "Intel Core i7-10750H at 2.60 GHz, 6 cores and 12 threads, up to 5.0 GHz",
      "spec.ram": "Memory",
      "spec.ram.v": "15 GB, plus 4 GB of swap",
      "spec.gpu": "GPU",
      "spec.gpu.v": "NVIDIA GeForce GTX 1650, 4 GB, driver 595.99.02, CUDA 13.2, 35 W cap",
      "spec.disk": "Disk",
      "spec.disk.v": "50 GB free.",
      "home.map": "Set up your [black-ops] environment",
      "card.llm": "Phase 1 · LocalAI",
      "card.llm.body": "Installation of the engine and a model that fits on the graphics card.",
      "card.agent": "Phase 2 · Agents",
      "card.agent.body": "Visual Studio Code + Cline, or the command line: cline-cli, OpenClaw, or Codex.",
      "card.mcp": "Phase 3 · MCPs",
      "card.mcp.body": "Orchestrator and Kali, from the product repository.",
      "card.lab": "Phase 4 · Labs",
      "card.lab.body": "Lab startup, monitoring, and three run types.",
      "card.qa": "Phase 5 · QA",
      "card.qa.body": "Review of the metrics from the run. Nothing is posted yet.",
      "llm.kicker": "Phase 1",
      "llm.title": "LocalAI installation.",
      "llm.lede": "Installation of the LocalAI LLM engine on the local Ubuntu machine. The script downloads a Docker image of the software and a small LLM, Qwen3.8-4B in Q4, for tests. It also downloads the llama.cpp backend and configures it for the 4 GB graphics card on this modest laptop.",
      "llm.access": "When it finishes, LocalAI is available locally at",
      "llm.warn": "It has no API key and it is not secured. Careful in production environments.",
      "llm.video.note": "LocalAI installation video + local model",
      "agent.kicker": "Phase 2",
      "agent.title": "Agent installation.",
      "agent.lede": "Agent installation phase. The goal is an agent connected to the LLM, with execution on the operating system, interaction with the MCPs, and read and write access to the filesystem.",
      "agent.options": "The product accepts several options. A few are already tested and sit here as examples.",
      "agent.gui": "Graphical interface",
      "agent.vscode": "Visual Studio Code + Cline",
      "agent.vscode.body": "Editor extension. It talks to LocalAI through the chat API. The installer writes the provider; the extension itself is installed in the editor.",
      "agent.cli": "Command line",
      "agent.cline": "cline-cli",
      "agent.cline.body": "The cline 3.0.46 package. It talks to LocalAI through the chat API. Its state stays in its own prefix.",
      "agent.openclaw": "OpenClaw",
      "agent.openclaw.body": "The openclaw package. The model goes through openai-completions, straight to LocalAI.",
      "agent.codex": "Codex",
      "agent.codex.body": "The @openai/codex package. With LocalAI it uses a proxy on 127.0.0.1:8082 that flattens the MCP tools from the Responses API.",
      "agent.from": "The installer lives in cli/install in the repository. Run it from that folder. LOCALAI_URL is this machine, http://127.0.0.1:8080.",
      "agent.video": "The installation video will be added here.",
      "agent.script": "The installation script will be added here.",
      "mcp.kicker": "Phase 3",
      "mcp.title": "MCP installation.",
      "mcp.lede": "The product is MVP Audit Orchestrator V2. This install adds two MCPs to the agent.",
      "mcp.clone": "Download",
      "mcp.clone.body": "On a clean environment, the repository is downloaded like this.",
      "mcp.install": "Installation",
      "mcp.install.body": "The install follows the repository README. It needs Python 3.11 or newer and Docker Compose v2. ./setup.sh creates the environment, the Kali image, the orchestrator databases, and the configuration of both MCPs.",
      "mcp.readme": "README",
      "mcp.pair": "The two MCPs",
      "mcp.orch": "Orchestrator",
      "mcp.orch.body": "It has two databases: a relational one, SQLite, and a non-relational one, Neo4j.",
      "mcp.kali": "Attacker",
      "mcp.kali.body": "A Kali Docker image, with an execution queue. Commands run in the background.",
      "lab.kicker": "Phase 4",
      "lab.title": "Labs and runs.",
      "lab.lede": "Three steps on this test machine: starting the lab, monitoring the environment, and a first run of each type.",
      "lab.setup": "Configure",
      "lab.setup.body": "Starting the labs. The setup_lab.sh script lives in the black-ops repository, at lab/setup_lab.sh. It asks which groups to bring up, ensures the ipvlan network, and starts only those profiles.",
      "lab.setup.file": "lab/setup_lab.sh",
      "lab.monitor": "Monitor",
      "lab.monitor.tag": "Monitor the environment",
      "lab.monitor.body": "Monitoring lab use. It watches the machine resources and the Docker containers that are running.",
      "lab.run": "First run",
      "lab.type1": "Type 1",
      "lab.type1.body": "It walks the graph of each port in Kali. It does not call the model.",
      "lab.type2": "Type 2",
      "lab.type2.body": "It does type 1. When a host's ports are finished, the model reviews that host.",
      "lab.type3": "Type 3",
      "lab.type3.body": "It does type 1. After each service the model can return a command. When the host closes, it does the same review as type 2.",
      "lab.video.soon": "The URL for this video is not available yet.",
      "video.localai": "LocalAI installation",
      "video.mode1": "Type 1 run",
      "video.mode2": "Type 2 run",
      "video.mode3": "Type 3 run",
      "qa.kicker": "Phase 5",
      "qa.title": "QA of the metrics from the run.",
      "qa.lede": "A check of whether the run actually says something. There are no metrics on the page yet: this phase opens when the first measured run is in.",
      "video.soon": "The video for this phase will be added here.",
      "code.title": "Installation",
      "code.pending": "The script for this phase will be added here.",
      "code.loadfail": "The script is in the link above.",
      "llm.code.note": "The script makes a folder in the home directory, or uses LOCALAI_DIR if it is set. It does not carry anyone else's paths. Run on the machine.",
      "llm.download": "Download install_localai.sh",
      "contact.kicker": "Contact",
      "contact.title": "Contact f0ns1",
      "contact.before": "Want to run your PoC, have questions, or want to expand the product?",
      "contact.linkedin": "LinkedIn",
      "contact.missing": "Want to run your PoC, have questions, or want to expand the product?",
      "footer.brand": "Workshop [black-ops]",
      "footer.tag": "Setting up your offensive environment"
    },
    es: {
      "meta.title": "Workshop [black-ops]",
      "meta.description": "Un workshop para montar [black-ops] en un portátil modesto: LocalAI, agentes, MCPs, una primera ejecución y una mirada a las métricas.",
      "skip": "Saltar al contenido",
      "lang.aria": "Idioma",
      "nav.aria": "Workshop",
      "brand.alt": "Marca de la hidra de tres cabezas",
      "brand.name": "Workshop",
      "brand.tag": "[black-ops]",
      "nav.llm": "LocalAI",
      "nav.agent": "Agentes",
      "nav.mcp": "MCPs",
      "nav.lab": "Laboratorios",
      "nav.qa": "QA",
      "home.kicker": "Tu máquina de prueba",
      "home.title": "Esto funciona en un portátil modesto.",
      "home.lede": "No hace falta un servidor. Montado en esta máquina de prueba: una gráfica de 4 GB y 15 GB de RAM. Si la máquina se parece, el workshop va. El sistema es Ubuntu 26.04.1 LTS.",
      "home.table": "Hardware del portátil modesto",
      "spec.part": "Pieza",
      "spec.value": "Lo que tiene",
      "spec.os": "Sistema",
      "spec.os.v": "Ubuntu 26.04.1 LTS (Resolute Raccoon)",
      "spec.cpu": "CPU",
      "spec.cpu.v": "Intel Core i7-10750H a 2,60 GHz, 6 núcleos y 12 hilos, hasta 5,0 GHz",
      "spec.ram": "Memoria",
      "spec.ram.v": "15 GB, más 4 GB de swap",
      "spec.gpu": "GPU",
      "spec.gpu.v": "NVIDIA GeForce GTX 1650, 4 GB, driver 595.99.02, CUDA 13.2, tope de 35 W",
      "spec.disk": "Disco",
      "spec.disk.v": "50 GB libres.",
      "home.map": "Monta tu entorno de [black-ops]",
      "card.llm": "Fase 1 · LocalAI",
      "card.llm.body": "Instalación del motor y de un modelo que cabe en la gráfica.",
      "card.agent": "Fase 2 · Agentes",
      "card.agent.body": "Visual Studio Code + Cline, o la línea de comandos: cline-cli, OpenClaw o Codex.",
      "card.mcp": "Fase 3 · MCPs",
      "card.mcp.body": "Orchestrator y Kali, desde el repositorio del producto.",
      "card.lab": "Fase 4 · Laboratorios",
      "card.lab.body": "Arranque del laboratorio, monitorización y tres tipos de ejecución.",
      "card.qa": "Fase 5 · QA",
      "card.qa.body": "Revisión de las métricas de la ejecución. Aún no hay nada colgado.",
      "llm.kicker": "Fase 1",
      "llm.title": "Instalación de LocalAI.",
      "llm.lede": "Instalación del motor de LLMs LocalAI en la máquina local con Ubuntu. El script descarga una imagen Docker del software y un LLM pequeño, Qwen3.8-4B en Q4, para pruebas. También descarga el backend llama.cpp y lo configura para la gráfica de 4 GB de este portátil modesto.",
      "llm.access": "Al terminar queda accesible en local en",
      "llm.warn": "No está configurado con clave de API ni securizado. Cuidado en entornos productivos.",
      "llm.video.note": "Video instalación LocalAI + modelo Local",
      "agent.kicker": "Fase 2",
      "agent.title": "Instalación de los agentes.",
      "agent.lede": "Fase de instalación del agente. El objetivo es un agente conectado al LLM, con ejecución en el sistema operativo, interacción con los MCPs, y lectura y escritura del sistema de ficheros.",
      "agent.options": "El producto admite varias opciones. Unas cuantas ya están probadas y quedan aquí como ejemplo.",
      "agent.gui": "Interfaz gráfica",
      "agent.vscode": "Visual Studio Code + Cline",
      "agent.vscode.body": "Extensión del editor. Habla con LocalAI por la API de chat. El instalador escribe el proveedor; la extensión se instala en el editor.",
      "agent.cli": "Línea de comandos",
      "agent.cline": "cline-cli",
      "agent.cline.body": "Paquete cline 3.0.46. Habla con LocalAI por la API de chat. El estado queda en su propio prefijo.",
      "agent.openclaw": "OpenClaw",
      "agent.openclaw.body": "Paquete openclaw. El modelo va por openai-completions, directo a LocalAI.",
      "agent.codex": "Codex",
      "agent.codex.body": "Paquete @openai/codex. Con LocalAI usa un proxy en 127.0.0.1:8082 que aplana las tools MCP de la API Responses.",
      "agent.from": "El instalador está en cli/install del repositorio. Se lanza desde esa carpeta. LOCALAI_URL es la de esta máquina, http://127.0.0.1:8080.",
      "agent.video": "El vídeo de instalación se añadirá aquí.",
      "agent.script": "El script de instalación se añadirá aquí.",
      "mcp.kicker": "Fase 3",
      "mcp.title": "Instalación de los MCPs.",
      "mcp.lede": "El producto es MVP Audit Orchestrator V2. Esta instalación añade dos MCP al agente.",
      "mcp.clone": "Descarga",
      "mcp.clone.body": "En un entorno limpio, el repositorio se descarga así.",
      "mcp.install": "Instalación",
      "mcp.install.body": "La instalación sigue el README del repositorio. Hace falta Python 3.11 o superior y Docker Compose v2. ./setup.sh crea el entorno, la imagen de Kali, las bases del orquestador y la configuración de los dos MCP.",
      "mcp.readme": "README",
      "mcp.pair": "Los dos MCP",
      "mcp.orch": "Orchestrator",
      "mcp.orch.body": "Cuenta con dos bases de datos: una relacional, SQLite, y otra no relacional, Neo4j.",
      "mcp.kali": "Atacante",
      "mcp.kali.body": "Imagen Docker de Kali, con una cola de ejecución. Los comandos corren en segundo plano.",
      "lab.kicker": "Fase 4",
      "lab.title": "Laboratorios y ejecuciones.",
      "lab.lede": "Tres pasos en esta máquina de prueba: arranque del laboratorio, monitorización del entorno y una ejecución inicial de cada tipo.",
      "lab.setup": "Configurar",
      "lab.setup.body": "Arranque de los laboratorios. El script setup_lab.sh está en el repositorio de black-ops, en lab/setup_lab.sh. Pregunta qué grupos levantar, asegura la red ipvlan y arranca solo esos perfiles.",
      "lab.setup.file": "lab/setup_lab.sh",
      "lab.monitor": "Monitorizar",
      "lab.monitor.tag": "Monitorizar el entorno",
      "lab.monitor.body": "Monitorización del uso del laboratorio. Mira los recursos de la máquina y los contenedores Docker en ejecución.",
      "lab.run": "Ejecución inicial",
      "lab.type1": "Tipo 1",
      "lab.type1.body": "Recorre el grafo de cada puerto en Kali. No llama al modelo.",
      "lab.type2": "Tipo 2",
      "lab.type2.body": "Hace el tipo 1. Cuando terminan los puertos de un host, el modelo revisa ese host.",
      "lab.type3": "Tipo 3",
      "lab.type3.body": "Hace el tipo 1. Tras cada servicio el modelo puede devolver un comando. Al cerrar el host hace la misma revisión que el tipo 2.",
      "lab.video.soon": "La URL de este vídeo aún no está disponible.",
      "video.localai": "Instalación de LocalAI",
      "video.mode1": "Ejecución del tipo 1",
      "video.mode2": "Ejecución del tipo 2",
      "video.mode3": "Ejecución del tipo 3",
      "qa.kicker": "Fase 5",
      "qa.title": "QA de las métricas obtenidas.",
      "qa.lede": "Revisión de si lo que salió de la ejecución tiene sentido. Todavía no hay métricas en la página: esta fase se abre cuando haya la primera ejecución medida.",
      "video.soon": "El vídeo de esta fase se añadirá aquí.",
      "code.title": "Instalación",
      "code.pending": "El script de esta fase se añadirá aquí.",
      "code.loadfail": "El script, desde el enlace de arriba.",
      "llm.code.note": "El script crea su carpeta dentro del directorio personal, o usa LOCALAI_DIR si está definida. No arrastra rutas de otra máquina. Ejecución en el equipo.",
      "llm.download": "Descargar install_localai.sh",
      "contact.kicker": "Contacto",
      "contact.title": "Contacta con f0ns1",
      "contact.before": "¿Quieres hacer tu PoC, Tienes dudas, quieres expandir el producto?",
      "contact.linkedin": "LinkedIn",
      "contact.missing": "¿Quieres hacer tu PoC, Tienes dudas, quieres expandir el producto?",
      "footer.brand": "Workshop [black-ops]",
      "footer.tag": "Montando tu entorno ofensivo"
    }
  };

  function stored() {
    try {
      var value = localStorage.getItem("course-lang");
      if (value === "es" || value === "en") return value;
    } catch (err) {}
    return "es";
  }

  function apply(lang) {
    var pack = packs[lang] || packs.es;
    document.documentElement.lang = lang;
    document.title = pack["meta.title"];
    var description = document.querySelector('meta[name="description"]');
    if (description) description.setAttribute("content", pack["meta.description"]);
    document.querySelectorAll("[data-i18n]").forEach(function (node) {
      var key = node.getAttribute("data-i18n");
      if (pack[key] != null) node.textContent = pack[key];
    });
    document.querySelectorAll("[data-i18n-aria]").forEach(function (node) {
      var key = node.getAttribute("data-i18n-aria");
      if (pack[key] != null) node.setAttribute("aria-label", pack[key]);
    });
    document.querySelectorAll("[data-i18n-label]").forEach(function (node) {
      var key = node.getAttribute("data-i18n-label");
      if (pack[key] != null) node.setAttribute("data-label", pack[key]);
    });
    document.querySelectorAll("[data-i18n-alt]").forEach(function (node) {
      var key = node.getAttribute("data-i18n-alt");
      if (pack[key] != null) node.alt = pack[key];
    });
    document.querySelectorAll("[data-set-lang]").forEach(function (node) {
      var on = node.getAttribute("data-set-lang") === lang;
      node.setAttribute("aria-pressed", on ? "true" : "false");
    });
    try { localStorage.setItem("course-lang", lang); } catch (err) {}
    window.SITE_I18N = { lang: lang, pack: pack };
    window.dispatchEvent(new CustomEvent("site-lang"));
  }

  document.querySelectorAll("[data-set-lang]").forEach(function (node) {
    node.addEventListener("click", function () {
      apply(node.getAttribute("data-set-lang"));
    });
  });

  apply(stored());
})();
