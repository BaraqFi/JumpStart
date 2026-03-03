// ─── COPY BUTTONS ────────────────────────────────────────────────
document.querySelectorAll('.copy-btn[data-copy]').forEach(btn => {
  btn.addEventListener('click', () => {
    const text = btn.getAttribute('data-copy').replace(/&#10;/g, '\n')
    navigator.clipboard.writeText(text).then(() => {
      const original = btn.textContent
      btn.textContent = '✓ copied'
      btn.classList.add('copied')
      setTimeout(() => {
        btn.textContent = original
        btn.classList.remove('copied')
      }, 2000)
    })
  })
})

// ─── CONFIGURATOR ────────────────────────────────────────────────
const isConfigPage = document.getElementById('categoryCards') !== null
if (isConfigPage) {

  // State
  let platform = 'mac'
  let selected = new Set(['essentials'])

  const RAW = 'https://raw.githubusercontent.com/baraqfi/jumpstart/main'

  const FLAGS = {
    essentials:   '--essentials',
    web:          '--web',
    python:       '--python',
    productivity: '--productivity',
    ai:           '--ai',
    linux:        '--linux',
  }

  // Elements
  const cards       = document.querySelectorAll('.cat-card')
  const countEl     = document.getElementById('selectedCount')
  const outputEl    = document.getElementById('commandOutput')
  const copyBtn     = document.getElementById('copyCommandBtn')
  const promptEl    = document.getElementById('terminalPrompt')
  const titleEl     = document.getElementById('terminalTitle')
  const inspectMac  = document.getElementById('inspectMac')
  const inspectWin  = document.getElementById('inspectWin')

  // Build the command string
  function buildCommand() {
    if (selected.size === 0) return ''

    const allIds = Object.keys(FLAGS)
    const isAll  = allIds.every(id => {
      if (id === 'linux' && platform === 'mac') return true // linux not applicable on mac
      return selected.has(id)
    })

    const flagStr = isAll
      ? '--all'
      : [...selected]
          .filter(id => !(id === 'linux' && platform === 'mac'))
          .map(id => FLAGS[id])
          .join(' ')

    if (!flagStr) return ''

    if (platform === 'mac') {
      return `curl -fsSL ${RAW}/mac/setup.sh | bash -s -- ${flagStr}`
    } else {
      return `$env:JS_FLAGS="${flagStr}"\nirm ${RAW}/windows/setup.ps1 | iex`
    }
  }

  // Render command into terminal
  function renderCommand() {
    const cmd = buildCommand()

    // Update count
    const visibleSelected = [...selected].filter(id => !(id === 'linux' && platform === 'mac'))
    countEl.textContent = `${visibleSelected.length} selected`

    if (!cmd) {
      outputEl.textContent = 'select categories above to generate your command...'
      outputEl.className = 'terminal-output placeholder'
      copyBtn.disabled = true
      copyBtn.textContent = 'copy command'
      return
    }

    outputEl.textContent = cmd
    outputEl.className = 'terminal-output'
    copyBtn.disabled = false

    // Store for copy
    copyBtn.setAttribute('data-cmd', cmd)
  }

  // Platform switch
  window.setPlatform = function(p) {
    platform = p
    document.body.className = `platform-${p}`

    // Update toggle buttons
    document.querySelectorAll('.platform-btn').forEach(btn => {
      btn.classList.toggle('active', btn.getAttribute('data-platform') === p)
    })

    // Update terminal UI
    promptEl.textContent  = p === 'mac' ? '$' : 'PS>'
    titleEl.textContent   = p === 'mac' ? 'Terminal' : 'PowerShell (Admin)'
    inspectMac.style.display = p === 'mac' ? '' : 'none'
    inspectWin.style.display = p === 'windows' ? '' : 'none'

    // Handle linux card
    const linuxCard = document.querySelector('[data-id="linux"]')
    if (linuxCard) {
      if (p === 'mac') {
        linuxCard.classList.add('unavailable')
        selected.delete('linux')
        linuxCard.classList.remove('selected')
      } else {
        linuxCard.classList.remove('unavailable')
      }
    }

    // Re-render cards
    updateCardStates()
    renderCommand()
  }

  // Toggle card
  window.toggleCard = function(card) {
    const id = card.getAttribute('data-id')
    if (card.classList.contains('unavailable')) return

    if (selected.has(id)) {
      selected.delete(id)
      card.classList.remove('selected')
    } else {
      selected.add(id)
      card.classList.add('selected')
    }

    renderCommand()
  }

  function updateCardStates() {
    cards.forEach(card => {
      const id = card.getAttribute('data-id')
      card.classList.toggle('selected', selected.has(id))
    })
  }

  // Select all / clear
  window.selectAll = function() {
    cards.forEach(card => {
      const id = card.getAttribute('data-id')
      if (!card.classList.contains('unavailable')) {
        selected.add(id)
        card.classList.add('selected')
      }
    })
    renderCommand()
  }

  window.clearAll = function() {
    selected.clear()
    cards.forEach(card => card.classList.remove('selected'))
    renderCommand()
  }

  // Copy command button
  window.copyCommand = function() {
    const cmd = copyBtn.getAttribute('data-cmd')
    if (!cmd) return
    navigator.clipboard.writeText(cmd).then(() => {
      copyBtn.textContent = '✓ copied!'
      copyBtn.classList.add('copied')
      setTimeout(() => {
        copyBtn.textContent = 'copy command'
        copyBtn.classList.remove('copied')
      }, 2000)
    })
  }

  // Init
  document.body.classList.add('platform-mac')
  updateCardStates()
  renderCommand()
}

// ─── TOC HIGHLIGHTING (docs) ───────────────────────────────────────
const tocLinks = document.querySelectorAll('.toc-link')
const sections = document.querySelectorAll('.doc-section')

if (tocLinks.length > 0 && sections.length > 0) {
  const observerOptions = {
    root: null,
    rootMargin: '-20% 0px -70% 0px',
    threshold: 0
  }

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.getAttribute('id')
        
        // Update active class
        tocLinks.forEach(link => {
          const isActive = link.getAttribute('href') === `#${id}`
          link.classList.toggle('active', isActive)
          
          // Scroll TOC horizontally on mobile to keep active link visible
          if (isActive && window.innerWidth <= 768) {
            const toc = link.parentElement
            const linkRect = link.getBoundingClientRect()
            const tocRect = toc.getBoundingClientRect()
            
            if (linkRect.left < tocRect.left || linkRect.right > tocRect.right) {
              link.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' })
            }
          }
        })
      }
    })
  }, observerOptions)

  sections.forEach(section => observer.observe(section))
}

// ─── SMOOTH SCROLL (docs TOC) ─────────────────────────────────────
tocLinks.forEach(link => {
  link.addEventListener('click', e => {
    const target = document.querySelector(link.getAttribute('href'))
    if (target) {
      e.preventDefault()
      const navHeight = 48
      const topOffset = target.getBoundingClientRect().top + window.pageYOffset - navHeight - 16
      window.scrollTo({ top: topOffset, behavior: 'smooth' })
      
      // Update hash without jump
      history.pushState(null, null, link.getAttribute('href'))
    }
  })
})
