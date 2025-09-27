#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');

class RobloxBundler {
    constructor() {
        this.modules = new Map();
        this.bundledCode = '';
    }

    // Extract module references from loadstring and require calls
    extractModuleReferences(code) {
        const references = [];
        
        // Extract GitHub URLs from loadstring calls
        const loadstringRegex = /loadstring\(game:HttpGet\('([^']+)'\)\)\(\)/g;
        let match;
        
        while ((match = loadstringRegex.exec(code)) !== null) {
            references.push({
                url: match[1],
                type: 'remote',
                originalCall: match[0]
            });
        }
        
        // Extract local file paths from require calls
        const requireRegex = /require\('([^']+)'\)/g;
        
        while ((match = requireRegex.exec(code)) !== null) {
            const modulePath = match[1];
            if (modulePath.startsWith('http')) {
                // Remote require
                references.push({
                    url: modulePath,
                    type: 'remote',
                    originalCall: match[0]
                });
            } else {
                // Local require
                references.push({
                    url: modulePath,
                    type: 'local',
                    originalCall: match[0]
                });
            }
        }
        
        return references;
    }

    // Convert GitHub URL to local module name
    urlToModuleName(url) {
        const parts = url.split('/');
        const filename = parts[parts.length - 1].replace('.lua', '');
        return filename.charAt(0).toUpperCase() + filename.slice(1) + 'Module';
    }

    // Check if URL is from our rbx-script-dev repository
    isLocalRepoUrl(url) {
        return url.includes('alfin-efendy/rbx-script-dev');
    }

    // Remove comments from Lua code
    removeComments(code) {
        const lines = code.split('\n');
        const cleanedLines = [];
        
        for (let line of lines) {
            // Remove single-line comments (--) but preserve strings
            let inString = false;
            let stringChar = null;
            let cleanedLine = '';
            let i = 0;
            
            while (i < line.length) {
                const char = line[i];
                const nextChar = line[i + 1];
                const prevChar = line[i - 1];
                
                // Handle string detection
                if (!inString && (char === '"' || char === "'")) {
                    inString = true;
                    stringChar = char;
                    cleanedLine += char;
                } else if (inString && char === stringChar && prevChar !== '\\') {
                    inString = false;
                    stringChar = null;
                    cleanedLine += char;
                } else if (!inString && char === '-' && nextChar === '-') {
                    // Found comment outside string, stop processing this line
                    break;
                } else {
                    cleanedLine += char;
                }
                i++;
            }
            
            // Only keep non-empty lines after trimming
            const trimmedLine = cleanedLine.trim();
            if (trimmedLine.length > 0) {
                cleanedLines.push(cleanedLine);
            }
        }
        
        return cleanedLines.join('\n');
    }

    // Load module from various sources
    async loadModule(moduleRef, basePath, isLocalOnly = false, options = {}) {
        const { url, type } = moduleRef;
        const moduleName = this.urlToModuleName(url);
        
        if (type === 'local') {
            // Handle local file require
            return await this.loadLocalModule(url, basePath, options);
        } else if (type === 'remote') {
            // Handle remote URL
            return await this.loadRemoteModule(url, isLocalOnly, options);
        }
        
        throw new Error(`Unknown module type: ${type} for ${url}`);
    }

    // Load local module file
    async loadLocalModule(relativePath, basePath, options = {}) {
        // Resolve the full path
        let fullPath = path.resolve(basePath, relativePath);
        
        // Add .lua extension if not present
        if (!fullPath.endsWith('.lua')) {
            fullPath += '.lua';
        }
        
        if (!fs.existsSync(fullPath)) {
            throw new Error(`Local module not found: ${fullPath}`);
        }
        
        let content = fs.readFileSync(fullPath, 'utf8');
        if (options.removeComments) {
            content = this.removeComments(content);
        }
        
        const moduleName = this.urlToModuleName(relativePath);
        console.log(`📁 Loaded local module: ${relativePath}`);
        
        return { name: moduleName, code: content, url: relativePath };
    }

    // Load remote module (original downloadModule functionality)
    async loadRemoteModule(url, isLocalOnly = false, options = {}) {
        const moduleName = this.urlToModuleName(url);
        
        // Check if it's from our local repository
        if (this.isLocalRepoUrl(url) && isLocalOnly) {
            // Try to load from local file first
            const baseRepoUrl = 'https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/';
            if (url.startsWith(baseRepoUrl)) {
                const relativePath = url.replace(baseRepoUrl, '');
                const localFilePath = path.join(__dirname, '..', relativePath);
                
                if (fs.existsSync(localFilePath)) {
                    let content = fs.readFileSync(localFilePath, 'utf8');
                    if (options.removeComments) {
                        content = this.removeComments(content);
                    }
                    console.log(`✅ Loaded ${relativePath} from LOCAL`);
                    return { name: moduleName, code: content, url: url };
                }
            }
        }
        
        // External URL not allowed in local-only mode
        if (isLocalOnly) {
            console.log(`❌ External URL not allowed in local-only mode: ${url}`);
            throw new Error(`External URL not allowed in local-only mode: ${url}`);
        }

        // Download from GitHub
        return new Promise((resolve, reject) => {
            https.get(url, (res) => {
                let data = '';
                
                res.on('data', (chunk) => {
                    data += chunk;
                });
                
                res.on('end', () => {
                    let processedData = data;
                    if (options.removeComments) {
                        processedData = this.removeComments(data);
                    }
                    console.log(`✅ Downloaded ${moduleName} from GitHub`);
                    resolve({ name: moduleName, code: processedData, url: url });
                });
            }).on('error', (err) => {
                console.error(`❌ Failed to download ${url}:`, err.message);
                reject(err);
            });
        });
    }

    // Bundle the main script with all dependencies
    async bundle(filePath, outputPath, options = {}) {
        const { localOnly = false, githubOnly = false, removeComments = true } = options;
        
        if (localOnly) {
            console.log('🔧 LOCAL-ONLY MODE: Will only use local files');
        } else if (githubOnly) {
            console.log('🌐 GITHUB-ONLY MODE: Will download all modules from GitHub');
        } else {
            console.log('🔄 HYBRID MODE: Will try local first, then GitHub');
        }
        
        if (options.removeComments) {
            console.log('✂️  COMMENT REMOVAL: Comments will be removed from code');
        } else {
            console.log('📝 COMMENT PRESERVATION: Comments will be preserved');
        }

        console.log('🚀 Starting Roblox Script Bundler...');
        
        // Read main script
        const mainScript = fs.readFileSync(filePath, 'utf8');
        console.log(`📖 Read main script: ${filePath}`);
        
        // Extract all module references (both loadstring and require)
        const moduleRefs = this.extractModuleReferences(mainScript);
        console.log(`🔍 Found ${moduleRefs.length} modules (${moduleRefs.filter(r => r.type === 'local').length} local, ${moduleRefs.filter(r => r.type === 'remote').length} remote)`);
        
        // Load all modules
        const modules = [];
        const basePath = path.dirname(filePath);
        
        for (const moduleRef of moduleRefs) {
            const moduleName = this.urlToModuleName(moduleRef.url);
            console.log(`⬇️  Loading ${moduleName} (${moduleRef.type})...`);
            
            try {
                const module = await this.loadModule(moduleRef, basePath, localOnly, options);
                modules.push({ ...moduleRef, ...module });
                
                // Recursively process dependencies in loaded module
                const subModuleRefs = this.extractModuleReferences(module.code);
                for (const subRef of subModuleRefs) {
                    // Avoid duplicate modules
                    const exists = modules.find(m => m.url === subRef.url);
                    if (!exists) {
                        console.log(`  📎 Loading dependency: ${this.urlToModuleName(subRef.url)}`);
                        try {
                            const subModule = await this.loadModule(subRef, basePath, localOnly, options);
                            modules.push({ ...subRef, ...subModule });
                        } catch (subError) {
                            console.log(`  ⚠️  Failed to load dependency: ${subError.message}`);
                            if (!localOnly) {
                                throw subError;
                            }
                        }
                    }
                }
                
            } catch (error) {
                console.log(`❌ Failed to load ${moduleName}: ${error.message}`);
                if (localOnly) {
                    // In local-only mode, continue without this module
                    continue;
                } else {
                    throw error;
                }
            }
        }
        
        // Generate bundled script
        let bundled = `-- 📦 BUNDLED ROBLOX SCRIPT
-- Generated by RobloxBundler
-- Date: ${new Date().toISOString()}

-- 📚 EMBEDDED MODULES
local EmbeddedModules = {}

`;

        // Add embedded modules
        for (const module of modules) {
            bundled += `-- Module: ${module.name}
EmbeddedModules["${module.url}"] = function()
${module.code.split('\n').map(line => '    ' + line).join('\n')}
end

`;
        }

        // Add simple loader function
        bundled += `-- 🔧 SMART MODULE LOADER
local function loadModule(url)
    -- Try embedded module first
    if EmbeddedModules[url] then
        return EmbeddedModules[url]()
    end
    
    -- Fallback to original loadstring
    print("🌐 [GITHUB] Loading from:", url)
    return loadstring(game:HttpGet(url))()
end

-- 🚀 MAIN SCRIPT
`;
        
        // Replace module calls in main script
        let modifiedMain = mainScript;
        for (const moduleRef of moduleRefs) {
            const newCall = `loadModule('${moduleRef.url}')`;
            modifiedMain = modifiedMain.replace(moduleRef.originalCall, newCall);
        }
        
        // Remove comments from main script if enabled
        if (options.removeComments) {
            modifiedMain = this.removeComments(modifiedMain);
        }
        
        bundled += modifiedMain;
        
        // Write bundled script
        fs.writeFileSync(outputPath, bundled);
        console.log(`✅ Bundle created: ${outputPath}`);
        console.log(`📊 Stats:`);
        console.log(`  - Modules bundled: ${modules.length}`);
        console.log(`  - Output size: ${(bundled.length / 1024).toFixed(2)} KB`);
        
        return bundled;
    }
}

// CLI handling
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log('Usage: node bundler.js <input.lua> <output.lua> [--local-only|--github-only|--hybrid] [--keep-comments]');
        process.exit(1);
    }
    
    const inputPath = path.resolve(args[0]);
    const outputPath = path.resolve(args[1]);
    
    const options = {};
    if (args.includes('--local-only')) {
        options.localOnly = true;
    } else if (args.includes('--github-only')) {
        options.githubOnly = true;
    }
    
    // By default, remove comments. Use --keep-comments to preserve them
    options.removeComments = !args.includes('--keep-comments');
    
    const bundler = new RobloxBundler();
    bundler.bundle(inputPath, outputPath, options)
        .then(() => {
            console.log('🎉 Bundling completed successfully!');
        })
        .catch((error) => {
            console.error('❌ Bundling failed:', error.message);
            process.exit(1);
        });
}

module.exports = RobloxBundler;