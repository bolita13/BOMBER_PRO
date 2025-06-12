#!/usr/bin/env zsh

# BOMBER PRO - Herramienta Avanzada de Reconocimiento Bug Bounty
# Autor: bolita13
# Versión: 1.0
# Descripción: Reconocimiento automatizado y evaluación integral de vulnerabilidades

# Definiciones de colores
readonly ROJO='\033[1;31m'
readonly VERDE='\033[1;32m'
readonly AMARILLO='\033[1;33m'
readonly AZUL='\033[1;34m'
readonly MAGENTA='\033[1;35m'
readonly CYAN='\033[1;36m'
readonly BLANCO='\033[1;37m'
readonly NEGRITA='\033[1m'
readonly RESET='\033[0m'
readonly FONDO_ROJO='\033[41m'
readonly FONDO_BLANCO='\033[47m'

# Variables globales
typeset -g DOMINIO_OBJETIVO=""
typeset -g DIR_TRABAJO=""
typeset -g TIMESTAMP=""
typeset -ga LISTA_SUBDOMINIOS=()
typeset -ga LISTA_URLS=()
typeset -ga URLS_VIVAS=()

# Función de logging
log_info() {
    echo -e "${CYAN}[INFO]${RESET} ${1}"
}

log_exito() {
    echo -e "${VERDE}[ÉXITO]${RESET} ${1}"
}

log_advertencia() {
    echo -e "${AMARILLO}[ADVERTENCIA]${RESET} ${1}"
}

log_error() {
    echo -e "${ROJO}[ERROR]${RESET} ${1}"
}

# Indicador de progreso
mostrar_progreso() {
    local tarea="$1"
    echo -e "${MAGENTA}[EJECUTANDO]${RESET} ${NEGRITA}${tarea}${RESET}"
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# Mostrar banner
mostrar_banner() {
    clear
    echo -e "${FONDO_ROJO}${BLANCO}${NEGRITA}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                  ║"
    echo "║    ██████╗  ██████╗ ██████╗ ██████╗ ███████╗██████╗             ║"
    echo "║    ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗            ║"
    echo "║    ██████╔╝██║   ██║██████╔╝██████╔╝█████╗  ██████╔╝            ║"
    echo "║    ██╔══██╗██║   ██║██╔══██╗██╔══██╗██╔══╝  ██╔══██╗            ║"
    echo "║    ██████╔╝╚██████╔╝██████╔╝██████╔╝███████╗██║  ██║            ║"
    echo "║    ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝            ║"
    echo "║                                                                  ║"
    echo "║                    ██████╗ ██████╗  ██████╗                     ║"
    echo "║                    ██╔══██╗██╔══██╗██╔═══██╗                    ║"
    echo "║                    ██████╔╝██████╔╝██║   ██║                    ║"
    echo "║                    ██╔═══╝ ██╔══██╗██║   ██║                    ║"
    echo "║                    ██║     ██║  ██║╚██████╔╝                    ║"
    echo "║                    ╚═╝     ╚═╝  ╚═╝ ╚═════╝                     ║"
    echo "║                                                                  ║"
    echo "║              Herramienta Avanzada de Bug Bounty                 ║"
    echo "║                        Versión 1.0                              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo
}

# Validación de dominio
validar_dominio() {
    local dominio="$1"
    if [[ ! "${dominio}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Obtener dominio objetivo
obtener_dominio_objetivo() {
    echo -e "${CYAN}${NEGRITA}Ingresa el dominio objetivo para reconocimiento:${RESET}"
    echo -e "${AMARILLO}Ejemplo: ejemplo.com${RESET}"
    echo -n -e "${BLANCO}Objetivo: ${RESET}"
    
    read DOMINIO_OBJETIVO
    
    if [[ -z "${DOMINIO_OBJETIVO}" ]]; then
        log_error "El dominio no puede estar vacío"
        exit 1
    fi
    
    if ! validar_dominio "${DOMINIO_OBJETIVO}"; then
        log_error "Formato de dominio inválido"
        exit 1
    fi
    
    log_exito "Dominio objetivo establecido: ${NEGRITA}${DOMINIO_OBJETIVO}${RESET}"
}

# Configurar directorio de trabajo
configurar_espacio_trabajo() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    DIR_TRABAJO="bomber_pro_${DOMINIO_OBJETIVO}_${TIMESTAMP}"
    
    if [[ -d "${DIR_TRABAJO}" ]]; then
        log_advertencia "El directorio existe, eliminando datos antiguos"
        rm -rf "${DIR_TRABAJO}"
    fi
    
    mkdir -p "${DIR_TRABAJO}"/{subdominios,urls,urls_vivas,vulnerabilidades,reportes}
    log_exito "Espacio de trabajo creado: ${DIR_TRABAJO}"
}

# Menú interactivo
mostrar_menu() {
    echo
    echo -e "${MAGENTA}${NEGRITA}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}${NEGRITA}                     OPCIONES DE RECONOCIMIENTO                    ${RESET}"
    echo -e "${MAGENTA}${NEGRITA}═══════════════════════════════════════════════════════════════════${RESET}"
    echo
    echo -e "${VERDE}1.${RESET} ${NEGRITA}Descubrimiento de Subdominios${RESET}  - Encontrar todos los subdominios"
    echo -e "${VERDE}2.${RESET} ${NEGRITA}Recopilación de URLs${RESET}           - Obtener URLs de archivos"
    echo -e "${VERDE}3.${RESET} ${NEGRITA}Rastreo Web${RESET}                   - Rastreo profundo con Katana"
    echo -e "${VERDE}4.${RESET} ${NEGRITA}Detección URLs Vivas${RESET}          - Filtrar endpoints activos"
    echo -e "${VERDE}5.${RESET} ${NEGRITA}Escaneo de Vulnerabilidades${RESET}   - Detección basada en Nuclei"
    echo -e "${VERDE}6.${RESET} ${NEGRITA}Generar Reporte${RESET}               - Reporte profesional en PDF"
    echo -e "${ROJO}7.${RESET} ${NEGRITA}RECONOCIMIENTO COMPLETO${RESET}       - Ejecutar todas las fases"
    echo -e "${AMARILLO}0.${RESET} ${NEGRITA}Salir${RESET}"
    echo
    echo -e "${MAGENTA}${NEGRITA}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -n -e "${BLANCO}Selecciona opción [0-7]: ${RESET}"
}

# Descubrimiento de subdominios
descubrimiento_subdominios() {
    mostrar_progreso "FASE 1: Descubrimiento de Subdominios"
    
    local archivo_subdominios="${DIR_TRABAJO}/subdominios/todos_subdominios.txt"
    local archivo_temporal="${DIR_TRABAJO}/subdominios/temp_subdominios.txt"
    
    # Assetfinder
    log_info "Ejecutando Assetfinder..."
    if command -v assetfinder >/dev/null 2>&1; then
        assetfinder --subs-only "${DOMINIO_OBJETIVO}" >> "${archivo_temporal}" 2>/dev/null
        local count_assetfinder=$(wc -l < "${archivo_temporal}" 2>/dev/null || echo "0")
        log_exito "Assetfinder encontró: ${count_assetfinder} subdominios"
    else
        log_advertencia "Assetfinder no está instalado"
    fi
    
    # Subfinder
    log_info "Ejecutando Subfinder..."
    if command -v subfinder >/dev/null 2>&1; then
        subfinder -all -silent -d "${DOMINIO_OBJETIVO}" >> "${archivo_temporal}" 2>/dev/null
        local count_actual=$(wc -l < "${archivo_temporal}" 2>/dev/null || echo "0")
        local subfinder_nuevos=$((count_actual - count_assetfinder))
        log_exito "Subfinder encontró: ${subfinder_nuevos} subdominios adicionales"
    else
        log_advertencia "Subfinder no está instalado"
    fi
    
    # Amass pasivo
    log_info "Ejecutando Amass (modo pasivo)..."
    if command -v amass >/dev/null 2>&1; then
        amass enum -passive -d "${DOMINIO_OBJETIVO}" >> "${archivo_temporal}" 2>/dev/null
        local count_final=$(wc -l < "${archivo_temporal}" 2>/dev/null || echo "0")
        local amass_nuevos=$((count_final - count_actual))
        log_exito "Amass encontró: ${amass_nuevos} subdominios adicionales"
    else
        log_advertencia "Amass no está instalado"
    fi
    
    # Wayback Machine URLs
    log_info "Consultando Wayback Machine..."
    if command -v curl >/dev/null 2>&1; then
        curl -s "http://web.archive.org/cdx/search/cdx?url=*.${DOMINIO_OBJETIVO}&output=txt&fl=original&collapse=urlkey" | \
        awk -F/ '{print $3}' | sort -u >> "${archivo_temporal}" 2>/dev/null
        log_exito "Datos de Wayback Machine recopilados"
    else
        log_advertencia "curl no está disponible"
    fi
    
    # Deduplicar y limpiar
    if [[ -f "${archivo_temporal}" ]]; then
        sort -u "${archivo_temporal}" | grep -E "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$" > "${archivo_subdominios}"
        rm -f "${archivo_temporal}"
        
        LISTA_SUBDOMINIOS=(${(f)"$(cat "${archivo_subdominios}")"})
        local total_subdominios=${#LISTA_SUBDOMINIOS[@]}
        log_exito "Total de subdominios únicos descubiertos: ${NEGRITA}${total_subdominios}${RESET}"
    else
        log_error "No se creó archivo de subdominios"
        return 1
    fi
}

# Recopilación y normalización de URLs
recopilacion_urls() {
    mostrar_progreso "FASE 2: Recopilación de URLs"
    
    local archivo_urls="${DIR_TRABAJO}/urls/todas_urls.txt"
    local archivo_urls_temp="${DIR_TRABAJO}/urls/urls_temp.txt"
    
    # Agregar dominio principal si no está en la lista
    if [[ ! " ${LISTA_SUBDOMINIOS[@]} " =~ " ${DOMINIO_OBJETIVO} " ]]; then
        LISTA_SUBDOMINIOS+=("${DOMINIO_OBJETIVO}")
    fi
    
    # Normalizar URLs (agregar http/https solo a las que no tengan)
    log_info "Normalizando URLs y agregando protocolos..."
    for subdominio in "${LISTA_SUBDOMINIOS[@]}"; do
        if [[ ! "${subdominio}" =~ ^https?:// ]]; then
            echo "https://${subdominio}" >> "${archivo_urls_temp}"
            echo "http://${subdominio}" >> "${archivo_urls_temp}"
        else
            echo "${subdominio}" >> "${archivo_urls_temp}"
        fi
    done
    
    # Deduplicar URLs
    sort -u "${archivo_urls_temp}" > "${archivo_urls}"
    rm -f "${archivo_urls_temp}"
    
    LISTA_URLS=(${(f)"$(cat "${archivo_urls}")"})
    local total_urls=${#LISTA_URLS[@]}
    log_exito "Total de URLs preparadas: ${NEGRITA}${total_urls}${RESET}"
}

# Rastreo web con Katana
rastreo_web() {
    mostrar_progreso "FASE 3: Rastreo Web con Katana"
    
    local archivo_urls="${DIR_TRABAJO}/urls/todas_urls.txt"
    local archivo_katana="${DIR_TRABAJO}/urls/katana_urls.txt"
    
    if [[ ! -f "${archivo_urls}" ]]; then
        log_error "Archivo de URLs no encontrado. Ejecute primero la recopilación de URLs."
        return 1
    fi
    
    log_info "Ejecutando Katana para rastreo profundo..."
    if command -v katana >/dev/null 2>&1; then
        katana -list "${archivo_urls}" -silent -jc -jsl -kf all -o "${archivo_katana}" 2>/dev/null
        
        if [[ -f "${archivo_katana}" ]]; then
            local count_katana=$(wc -l < "${archivo_katana}" 2>/dev/null || echo "0")
            log_exito "Katana descubrió: ${NEGRITA}${count_katana}${RESET} URLs adicionales"
            
            # Combinar URLs originales con las de Katana
            cat "${archivo_urls}" "${archivo_katana}" | sort -u > "${DIR_TRABAJO}/urls/urls_combinadas.txt"
            
            LISTA_URLS=(${(f)"$(cat "${DIR_TRABAJO}/urls/urls_combinadas.txt")"})
            local total_combinadas=${#LISTA_URLS[@]}
            log_exito "Total de URLs después del rastreo: ${NEGRITA}${total_combinadas}${RESET}"
        else
            log_advertencia "Katana no generó resultados"
        fi
    else
        log_advertencia "Katana no está instalado"
    fi
}

# Detección de URLs vivas
deteccion_urls_vivas() {
    mostrar_progreso "FASE 4: Detección de URLs Vivas con HTTPx"
    
    local archivo_urls_combinadas="${DIR_TRABAJO}/urls/urls_combinadas.txt"
    local archivo_urls_vivas="${DIR_TRABAJO}/urls_vivas/urls_vivas.txt"
    
    if [[ ! -f "${archivo_urls_combinadas}" ]]; then
        log_error "Archivo de URLs combinadas no encontrado"
        return 1
    fi
    
    log_info "Ejecutando HTTPx para filtrar URLs activas..."
    if command -v httpx >/dev/null 2>&1; then
        httpx -list "${archivo_urls_combinadas}" -silent -o "${archivo_urls_vivas}" 2>/dev/null
        
        if [[ -f "${archivo_urls_vivas}" ]]; then
            URLS_VIVAS=(${(f)"$(cat "${archivo_urls_vivas}")"})
            local total_vivas=${#URLS_VIVAS[@]}
            log_exito "URLs vivas detectadas: ${NEGRITA}${total_vivas}${RESET}"
        else
            log_error "HTTPx no generó resultados"
            return 1
        fi
    else
        log_error "HTTPx no está instalado"
        return 1
    fi
}

# Escaneo de vulnerabilidades
escaneo_vulnerabilidades() {
    mostrar_progreso "FASE 5: Escaneo de Vulnerabilidades"
    
    local archivo_urls_vivas="${DIR_TRABAJO}/urls_vivas/urls_vivas.txt"
    local dir_vulnerabilidades="${DIR_TRABAJO}/vulnerabilidades"
    
    if [[ ! -f "${archivo_urls_vivas}" ]]; then
        log_error "Archivo de URLs vivas no encontrado"
        return 1
    fi
    
    # Patrones GF más comunes
    local -a patrones_gf=(
        "xss"
        "sqli"
        "lfi"
        "rce"
        "idor"
        "ssrf"
        "redirect"
        "secrets"
        "debug"
        "api-keys"
        "cors"
    )
    
    # Verificar si gf está instalado
    if ! command -v gf >/dev/null 2>&1; then
        log_advertencia "GF no está instalado, saltando clasificación de patrones"
        # Ejecutar Nuclei directamente en todas las URLs
        log_info "Ejecutando Nuclei en todas las URLs vivas..."
        if command -v nuclei >/dev/null 2>&1; then
            nuclei -list "${archivo_urls_vivas}" -silent -o "${dir_vulnerabilidades}/todas_vulnerabilidades.txt" 2>/dev/null
            log_exito "Escaneo de Nuclei completado"
        else
            log_error "Nuclei no está instalado"
            return 1
        fi
        return 0
    fi
    
    # Procesar cada patrón GF
    for patron in "${patrones_gf[@]}"; do
        log_info "Procesando patrón: ${patron}"
        
        local archivo_patron="${dir_vulnerabilidades}/${patron}.txt"
        local archivo_resultados="${dir_vulnerabilidades}/${patron}_vulnerabilidades.txt"
        
        # Aplicar patrón GF
        gf "${patron}" < "${archivo_urls_vivas}" > "${archivo_patron}" 2>/dev/null
        
        if [[ -s "${archivo_patron}" ]]; then
            local count_patron=$(wc -l < "${archivo_patron}" 2>/dev/null || echo "0")
            log_exito "Patrón ${patron}: ${count_patron} URLs candidatas"
            
            # Ejecutar Nuclei en URLs del patrón
            if command -v nuclei >/dev/null 2>&1; then
                nuclei -list "${archivo_patron}" -tags "${patron}" -silent -o "${archivo_resultados}" 2>/dev/null
                
                if [[ -s "${archivo_resultados}" ]]; then
                    local count_vulns=$(wc -l < "${archivo_resultados}" 2>/dev/null || echo "0")
                    log_exito "Vulnerabilidades ${patron}: ${NEGRITA}${count_vulns}${RESET} encontradas"
                else
                    log_info "No se encontraron vulnerabilidades para patrón: ${patron}"
                fi
            fi
        else
            log_info "No hay candidatos para patrón: ${patron}"
        fi
    done
    
    log_exito "Escaneo de vulnerabilidades completado"
}

# Generar reporte profesional
generar_reporte() {
    mostrar_progreso "FASE 6: Generación de Reporte Profesional"
    
    local archivo_reporte_md="${DIR_TRABAJO}/reportes/reporte_${DOMINIO_OBJETIVO}_${TIMESTAMP}.md"
    local archivo_reporte_pdf="${DIR_TRABAJO}/reportes/reporte_${DOMINIO_OBJETIVO}_${TIMESTAMP}.pdf"
    
    log_info "Generando reporte en Markdown..."
    
    # Crear reporte en Markdown
    cat > "${archivo_reporte_md}" << EOF
# 🔍 Reporte de Reconocimiento Bug Bounty

**Objetivo:** ${DOMINIO_OBJETIVO}  
**Fecha:** $(date '+%d/%m/%Y %H:%M:%S')  
**Herramienta:** BOMBER PRO v1.0  
**Investigador:** Security Researcher  

---

## 📊 Resumen Ejecutivo

Este reporte presenta los resultados del reconocimiento automatizado realizado sobre el dominio objetivo **${DOMINIO_OBJETIVO}**. El análisis incluye descubrimiento de subdominios, recopilación de URLs, rastreo web y evaluación de vulnerabilidades.

---

## 🌐 Descubrimiento de Subdominios

### Metodología
- **Assetfinder:** Descubrimiento basado en certificados y DNS
- **Subfinder:** Fuentes múltiples de inteligencia
- **Amass:** Reconocimiento pasivo avanzado
- **Wayback Machine:** Análisis de archivos históricos

### Resultados
EOF

    # Agregar estadísticas de subdominios
    if [[ -f "${DIR_TRABAJO}/subdominios/todos_subdominios.txt" ]]; then
        local total_subdominios=$(wc -l < "${DIR_TRABAJO}/subdominios/todos_subdominios.txt" 2>/dev/null || echo "0")
        echo "- **Total de subdominios únicos:** ${total_subdominios}" >> "${archivo_reporte_md}"
        echo "" >> "${archivo_reporte_md}"
        echo "### Lista de Subdominios" >> "${archivo_reporte_md}"
        echo '```' >> "${archivo_reporte_md}"
        head -20 "${DIR_TRABAJO}/subdominios/todos_subdominios.txt" >> "${archivo_reporte_md}"
        if [[ ${total_subdominios} -gt 20 ]]; then
            echo "... y $((total_subdominios - 20)) más" >> "${archivo_reporte_md}"
        fi
        echo '```' >> "${archivo_reporte_md}"
    fi
    
    # Agregar sección de URLs
    cat >> "${archivo_reporte_md}" << EOF

---

## 🔗 Análisis de URLs

### Rastreo Web
EOF

    if [[ -f "${DIR_TRABAJO}/urls_vivas/urls_vivas.txt" ]]; then
        local total_urls_vivas=$(wc -l < "${DIR_TRABAJO}/urls_vivas/urls_vivas.txt" 2>/dev/null || echo "0")
        echo "- **URLs activas detectadas:** ${total_urls_vivas}" >> "${archivo_reporte_md}"
    fi
    
    # Agregar sección de vulnerabilidades
    cat >> "${archivo_reporte_md}" << EOF

---

## 🚨 Evaluación de Vulnerabilidades

### Metodología de Análisis
- **Herramienta principal:** Nuclei Engine
- **Patrones analizados:** XSS, SQLi, LFI, RCE, IDOR, SSRF, Open Redirect, Secrets, Debug, API Keys
- **Enfoque:** Análisis automatizado con validación de falsos positivos

### Resultados por Categoría

EOF

    # Agregar resultados de vulnerabilidades por categoría
    local dir_vulnerabilidades="${DIR_TRABAJO}/vulnerabilidades"
    local total_vulnerabilidades=0
    
    local -a categorias_severidad=(
        "rce:CRÍTICA"
        "sqli:ALTA"
        "xss:MEDIA"
        "lfi:MEDIA"
        "ssrf:MEDIA"
        "idor:MEDIA"
        "redirect:BAJA"
        "secrets:ALTA"
        "debug:BAJA"
        "api-keys:ALTA"
    )
    
    for categoria_sev in "${categorias_severidad[@]}"; do
        local categoria="${categoria_sev%%:*}"
        local severidad="${categoria_sev##*:}"
        local archivo_vuln="${dir_vulnerabilidades}/${categoria}_vulnerabilidades.txt"
        
        if [[ -f "${archivo_vuln}" && -s "${archivo_vuln}" ]]; then
            local count_vuln=$(wc -l < "${archivo_vuln}" 2>/dev/null || echo "0")
            total_vulnerabilidades=$((total_vulnerabilidades + count_vuln))
            
            # Determinar emoji y color según severidad
            local emoji=""
            local color_badge=""
            case "${severidad}" in
                "CRÍTICA") emoji="🔴"; color_badge="![CRÍTICA](https://img.shields.io/badge/CRÍTICA-red)" ;;
                "ALTA") emoji="🟠"; color_badge="![ALTA](https://img.shields.io/badge/ALTA-orange)" ;;
                "MEDIA") emoji="🟡"; color_badge="![MEDIA](https://img.shields.io/badge/MEDIA-yellow)" ;;
                "BAJA") emoji="🔵"; color_badge="![BAJA](https://img.shields.io/badge/BAJA-blue)" ;;
            esac
            
            cat >> "${archivo_reporte_md}" << EOF
#### ${emoji} ${categoria^^} ${color_badge}

**Cantidad detectada:** ${count_vuln}  
**Severidad:** ${severidad}  

**Descripción del riesgo:**
EOF
            
            # Agregar descripción específica del riesgo
            case "${categoria}" in
                "xss")
                    cat >> "${archivo_reporte_md}" << EOF
Las vulnerabilidades de Cross-Site Scripting (XSS) permiten a atacantes inyectar scripts maliciosos en aplicaciones web, comprometiendo la integridad de los datos del usuario y permitiendo el robo de credenciales.

**Mitigación recomendada:**
- Implementar validación y sanitización estricta de inputs
- Utilizar Content Security Policy (CSP)
- Escapar correctamente los datos de salida
- Validar y filtrar todos los datos del usuario
EOF
                    ;;
                "sqli")
                    cat >> "${archivo_reporte_md}" << EOF
Las vulnerabilidades de inyección SQL permiten a atacantes manipular consultas de base de datos, potencialmente comprometiendo toda la información almacenada y el control del sistema.

**Mitigación recomendada:**
- Utilizar consultas preparadas (prepared statements)
- Implementar validación estricta de inputs
- Aplicar principio de menor privilegio en bases de datos
- Realizar auditorías regulares de código
EOF
                    ;;
                "rce")
                    cat >> "${archivo_reporte_md}" << EOF
Las vulnerabilidades de ejecución remota de código (RCE) representan el mayor riesgo de seguridad, permitiendo a atacantes ejecutar comandos arbitrarios en el servidor objetivo.

**Mitigación recomendada:**
- Eliminar o restringir funciones peligrosas
- Implementar sandboxing y containerización
- Validación exhaustiva de inputs
- Monitoreo y logging avanzado
EOF
                    ;;
                "lfi")
                    cat >> "${archivo_reporte_md}" << EOF
Las vulnerabilidades de inclusión local de archivos (LFI) permiten acceder a archivos del sistema, potencialmente exponiendo información sensible y credenciales.

**Mitigación recomendada:**
- Validar y sanitizar rutas de archivos
- Implementar listas blancas para archivos permitidos
- Usar rutas absolutas y validadas
- Restringir permisos de acceso a archivos
EOF
                    ;;
                "ssrf")
                    cat >> "${archivo_reporte_md}" << EOF
Las vulnerabilidades de falsificación de solicitudes del lado del servidor (SSRF) permiten a atacantes realizar solicitudes desde el servidor hacia recursos internos.

**Mitigación recomendada:**
- Validar y filtrar URLs de destino
- Implementar listas blancas de dominios permitidos
- Usar proxies y firewalls internos
- Monitorear tráfico de red interno
EOF
                    ;;
                *)
                    cat >> "${archivo_reporte_md}" << EOF
Vulnerabilidad detectada que requiere revisión manual para determinar el impacto real y las medidas de mitigación específicas.

**Mitigación recomendada:**
- Revisar manualmente cada instancia
- Aplicar principios de seguridad por diseño
- Implementar controles de acceso apropiados
EOF
                    ;;
            esac
            
            echo "" >> "${archivo_reporte_md}"
            echo "**Ejemplos detectados:**" >> "${archivo_reporte_md}"
            echo '```' >> "${archivo_reporte_md}"
            head -5 "${archivo_vuln}" >> "${archivo_reporte_md}"
            echo '```' >> "${archivo_reporte_md}"
            echo "" >> "${archivo_reporte_md}"
        fi
    done
    
    # Agregar sección de conclusiones
    cat >> "${archivo_reporte_md}" << EOF

---

## 📈 Análisis de Riesgo Global

### Resumen de Hallazgos
- **Total de vulnerabilidades detectadas:** ${total_vulnerabilidades}
- **Nivel de riesgo general:** $(if [[ ${total_vulnerabilidades} -gt 20 ]]; then echo "ALTO"; elif [[ ${total_vulnerabilidades} -gt 5 ]]; then echo "MEDIO"; else echo "BAJO"; fi)

### Recomendaciones Prioritarias

1. **🔴 Crítico:** Abordar inmediatamente vulnerabilidades RCE y SQLi
2. **🟠 Alto:** Implementar controles de seguridad para XSS y exposición de secretos
3. **🟡 Medio:** Revisar configuraciones de seguridad y validación de inputs
4. **🔵 Bajo:** Fortalecer monitoreo y logging de seguridad

### Próximos Pasos

1. **Validación Manual:** Confirmar vulnerabilidades detectadas automáticamente
2. **Pruebas de Penetración:** Realizar testing manual dirigido
3. **Remediación:** Implementar fixes según prioridad de riesgo
4. **Re-testing:** Verificar efectividad de las correcciones aplicadas

---

## 🛠️ Metodología Técnica

### Herramientas Utilizadas
- **Assetfinder:** Descubrimiento de subdominios
- **Subfinder:** Enumeración de subdominios con múltiples fuentes
- **Amass:** Reconocimiento pasivo avanzado
- **Katana:** Rastreador web y recopilación de URLs
- **HTTPx:** Verificación de servicios activos
- **GF:** Clasificación de patrones de vulnerabilidad
- **Nuclei:** Motor de detección de vulnerabilidades

### Limitaciones del Análisis
- Análisis automatizado sin validación manual
- Posibles falsos positivos que requieren verificación
- Cobertura limitada a patrones conocidos
- Sin testing de lógica de negocio específica

---

## 📞 Información de Contacto

**Investigador:** Security Researcher  
**Herramienta:** BOMBER PRO v1.0  
**Fecha de análisis:** $(date '+%d/%m/%Y')

---

*Este reporte ha sido generado automáticamente. Se recomienda validación manual de todos los hallazgos antes de proceder con la remediación.*
EOF

    log_exito "Reporte Markdown generado: ${archivo_reporte_md}"
    
    # Generar PDF con pandoc
    log_info "Convirtiendo reporte a PDF..."
    if command -v pandoc >/dev/null 2>&1; then
        pandoc "${archivo_reporte_md}" -o "${archivo_reporte_pdf}" \
            --pdf-engine=xelatex \
            --variable geometry:margin=2cm \
            --variable fontsize=11pt \
            --variable colorlinks=true \
            --toc \
            2>/dev/null
        
        if [[ -f "${archivo_reporte_pdf}" ]]; then
            log_exito "Reporte PDF generado: ${archivo_reporte_pdf}"
        else
            log_advertencia "No se pudo generar PDF. Verifique que pandoc y xelatex estén instalados"
        fi
    else
        log_advertencia "Pandoc no está instalado. Solo se generó reporte en Markdown"
    fi
    
    # Mostrar resumen final
    echo
    echo -e "${MAGENTA}${NEGRITA}═══════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}${NEGRITA}                        RESUMEN FINAL                              ${RESET}"
    echo -e "${MAGENTA}${NEGRITA}═══════════════════════════════════════════════════════════════════${RESET}"
    echo
    echo -e "${VERDE}📁 Directorio de trabajo:${RESET} ${NEGRITA}${DIR_TRABAJO}${RESET}"
    echo -e "${VERDE}📋 Reporte Markdown:${RESET} ${archivo_reporte_md}"
    if [[ -f "${archivo_reporte_pdf}" ]]; then
        echo -e "${VERDE}📄 Reporte PDF:${RESET} ${archivo_reporte_pdf}"
    fi
    echo -e "${VERDE}🎯 Dominio analizado:${RESET} ${NEGRITA}${DOMINIO_OBJETIVO}${RESET}"
    echo -e "${VERDE}⏰ Tiempo de análisis:${RESET} $(date '+%H:%M:%S')"
    echo
}

# Reconocimiento completo
reconocimiento_completo() {
    log_info "Iniciando reconocimiento completo del dominio: ${NEGRITA}${DOMINIO_OBJETIVO}${RESET}"
    echo
    
    descubrimiento_subdominios || { log_error "Fallo en descubrimiento de subdominios"; return 1; }
    echo
    
    recopilacion_urls || { log_error "Fallo en recopilación de URLs"; return 1; }
    echo
    
    rastreo_web || { log_error "Fallo en rastreo web"; return 1; }
    echo
    
    deteccion_urls_vivas || { log_error "Fallo en detección de URLs vivas"; return 1; }
    echo
    
    escaneo_vulnerabilidades || { log_error "Fallo en escaneo de vulnerabilidades"; return 1; }
    echo
    
    generar_reporte || { log_error "Fallo en generación de reporte"; return 1; }
    
    log_exito "¡Reconocimiento completo finalizado exitosamente!"
}

# Verificar dependencias
verificar_dependencias() {
    local -a herramientas_requeridas=(
        "assetfinder"
        "subfinder" 
        "amass"
        "curl"
        "katana"
        "httpx"
        "gf"
        "nuclei"
    )
    
    local -a herramientas_opcionales=(
        "pandoc"
    )
    
    local faltantes=()
    
    for herramienta in "${herramientas_requeridas[@]}"; do
        if ! command -v "${herramienta}" >/dev/null 2>&1; then
            faltantes+=("${herramienta}")
        fi
    done
    
    if [[ ${#faltantes[@]} -gt 0 ]]; then
        log_advertencia "Herramientas faltantes: ${faltantes[*]}"
        echo -e "${AMARILLO}El script funcionará con funcionalidad limitada${RESET}"
        echo
    fi
    
    for herramienta in "${herramientas_opcionales[@]}"; do
        if ! command -v "${herramienta}" >/dev/null 2>&1; then
            log_advertencia "Herramienta opcional no encontrada: ${herramienta}"
        fi
    done
}

# Función principal
main() {
    # Verificar que estamos en zsh
    if [[ -z "${ZSH_VERSION}" ]]; then
        echo -e "${ROJO}Error: Este script requiere zsh${RESET}"
        exit 1
    fi
    
    mostrar_banner
    verificar_dependencias
    obtener_dominio_objetivo
    configurar_espacio_trabajo
    
    while true; do
        mostrar_menu
        read opcion
        
        case "${opcion}" in
            1)
                echo
                descubrimiento_subdominios
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
            2)
                echo
                if [[ ${#LISTA_SUBDOMINIOS[@]} -eq 0 ]]; then
                    log_advertencia "Primero ejecute el descubrimiento de subdominios"
                else
                    recopilacion_urls
                fi
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
            3)
                echo
                rastreo_web
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
            4)
                echo
                deteccion_urls_vivas
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
            5)
                echo
                escaneo_vulnerabilidades
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
            6)
                echo
                generar_reporte
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
            7)
                echo
                reconocimiento_completo
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
            0)
                echo
                log_info "Saliendo de BOMBER PRO..."
                echo -e "${CYAN}¡Gracias por usar BOMBER PRO!${RESET}"
                exit 0
                ;;
            *)
                echo
                log_error "Opción inválida. Seleccione un número del 0 al 7."
                echo
                echo -e "${VERDE}Presiona Enter para continuar...${RESET}"
                read
                ;;
        esac
    done
}

# Manejo de señales para limpieza
cleanup() {
    echo
    log_info "Limpiando y saliendo..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Ejecutar función principal
main "$@"
