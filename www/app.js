"use strict";

const apiBase = "/yunohost/portalapi";

function element(identifier) {
  return document.getElementById(identifier);
}

function firstName(fullName, username) {
  const name = String(fullName || "").trim();
  return name.split(/\s+/)[0] || username;
}

function safeUrl(value) {
  try {
    const url = new URL(value, window.location.origin);
    return ["http:", "https:"].includes(url.protocol) ? url.href : null;
  } catch (_) {
    return null;
  }
}

function applicationUrl(value) {
  const source = String(value || "").trim();
  if (source.startsWith("/")) return safeUrl(source);
  return safeUrl(source.includes("://") ? source : `https://${source.replace(/^\/+/, "")}`);
}

function imageUrl(value) {
  return applicationUrl(value) || "logo-arcenal.svg";
}

function localizedDescription(value) {
  if (typeof value === "string") return value;
  if (!value || typeof value !== "object") return "Service ARCenal";
  return String(value.fr || value.en || Object.values(value).find((item) => typeof item === "string") || "Service ARCenal");
}

function createApplication(app) {
  const item = document.createElement("li");
  const image = document.createElement("img");
  const title = document.createElement("h3");
  const link = document.createElement("a");
  const description = document.createElement("p");
  const href = applicationUrl(app.url);
  item.className = "carte-application";
  image.className = "icone-application";
  image.src = imageUrl(app.logo);
  image.alt = "";
  title.className = "nom-application";
  link.href = href || "#";
  link.textContent = String(app.label || "Application");
  if (!href) link.setAttribute("aria-disabled", "true");
  description.className = "description-application";
  description.textContent = localizedDescription(app.description);
  title.append(link);
  item.append(image, title, description);
  return item;
}

function renderApplications(apps) {
  const list = element("liste-applications");
  const status = element("etat-applications");
  const entries = Object.values(apps || {});
  list.replaceChildren(...entries.map(createApplication));
  status.hidden = entries.length > 0;
  status.textContent = entries.length ? "" : "Aucune application ne vous est attribuée pour le moment.";
  element("compteur-applications").textContent = `${entries.length} service${entries.length > 1 ? "s" : ""}`;
}

function renderNews(configuration) {
  const news = configuration || {};
  element("titre-nouvelle").textContent = news.newsTitle || "Bienvenue dans ARCenal";
  element("contenu-nouvelle").textContent = news.newsContent || "Votre espace personnel rassemble vos services autorisés.";
  const link = element("lien-nouvelle");
  const href = safeUrl(news.newsUrl);
  link.hidden = !href;
  if (href) link.href = href;
}

function applyTheme(configuration) {
  const theme = ["light", "dark", "system"].includes(configuration.theme) ? configuration.theme : "system";
  document.documentElement.dataset.theme = theme;
}

function renderIdentity(settings, user) {
  const displayName = firstName(user.fullname, user.username);
  element("salutation").textContent = `Bonjour ${displayName}`;
  element("introduction").textContent = settings.portal_user_intro || "Voici les services disponibles pour votre activité.";
  if (typeof settings.portal_logo === "string" && settings.portal_logo) {
    element("marque-logo").src = `/yunohost/sso/customassets/${settings.portal_logo}`;
  }
  element("lien-administration").hidden = !Array.isArray(user.groups) || !user.groups.includes("admins");
}

async function loadJson(url) {
  const response = await fetch(url, { credentials: "include", cache: "no-store" });
  if (!response.ok) throw new Error(`Réponse inattendue : ${response.status}`);
  return response.json();
}

async function initializeDashboard() {
  try {
    const [settings, user, configuration] = await Promise.all([
      loadJson(`${apiBase}/public`),
      loadJson(`${apiBase}/me`),
      loadJson("configuration.json"),
    ]);
    renderIdentity(settings, user);
    applyTheme(configuration);
    renderNews(configuration);
    renderApplications(user.apps);
    element("application").setAttribute("aria-busy", "false");
  } catch (_) {
    element("etat-applications").textContent = "Votre session a expiré. Rechargez cette page pour vous reconnecter.";
    element("introduction").textContent = "Nous ne pouvons pas charger votre espace personnel.";
  }
}

function logout() {
  window.location.assign("/espace-perso/deconnexion");
}

element("deconnexion").addEventListener("click", logout);
initializeDashboard();
