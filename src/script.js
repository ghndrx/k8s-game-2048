// 2048 Game JavaScript - Knative Edition

class Game2048 {
    constructor() {
        this.grid = [];
        this.score = 0;
        this.best = localStorage.getItem('best2048') || 0;
        this.gameWon = false;
        this.gameOver = false;
        this.keepPlaying = false;
        
        this.init();
        this.setupEventListeners();
        this.setEnvironment();
    }

    init() {
        this.grid = [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0]
        ];
        
        this.score = 0;
        this.gameWon = false;
        this.gameOver = false;
        this.keepPlaying = false;
        
        this.updateScore();
        this.addRandomTile();
        this.addRandomTile();
        this.updateDisplay();
    }

    setEnvironment() {
        const envElement = document.getElementById('environment');
        const envBadge = document.getElementById('env-badge');
        
        // Try to detect environment from hostname
        const hostname = window.location.hostname;
        let environment = 'production';
        
        if (hostname.includes('dev')) {
            environment = 'development';
        } else if (hostname.includes('staging')) {
            environment = 'staging';
        }
        
        envElement.textContent = environment.charAt(0).toUpperCase() + environment.slice(1);
        envBadge.textContent = environment;
        envBadge.className = `environment-badge ${environment}`;
    }

    setupEventListeners() {
        document.addEventListener('keydown', (e) => this.handleKeyPress(e));
        document.getElementById('restart-button').addEventListener('click', () => this.restart());
        document.getElementById('keep-playing-button').addEventListener('click', () => this.keepPlayingGame());
        document.getElementById('retry-button').addEventListener('click', () => this.restart());
        
        // Touch/swipe support for mobile
        let startX, startY;
        
        document.addEventListener('touchstart', (e) => {
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
        });
        
        document.addEventListener('touchend', (e) => {
            if (!startX || !startY) return;
            
            const endX = e.changedTouches[0].clientX;
            const endY = e.changedTouches[0].clientY;
            
            const diffX = startX - endX;
            const diffY = startY - endY;
            
            if (Math.abs(diffX) > Math.abs(diffY)) {
                if (diffX > 0) {
                    this.move('left');
                } else {
                    this.move('right');
                }
            } else {
                if (diffY > 0) {
                    this.move('up');
                } else {
                    this.move('down');
                }
            }
        });
    }

    handleKeyPress(e) {
        if (this.gameOver && !this.keepPlaying) return;
        
        switch (e.code) {
            case 'ArrowUp':
                e.preventDefault();
                this.move('up');
                break;
            case 'ArrowDown':
                e.preventDefault();
                this.move('down');
                break;
            case 'ArrowLeft':
                e.preventDefault();
                this.move('left');
                break;
            case 'ArrowRight':
                e.preventDefault();
                this.move('right');
                break;
        }
    }

    move(direction) {
        const previousGrid = this.grid.map(row => [...row]);
        let moved = false;

        switch (direction) {
            case 'left':
                moved = this.moveLeft();
                break;
            case 'right':
                moved = this.moveRight();
                break;
            case 'up':
                moved = this.moveUp();
                break;
            case 'down':
                moved = this.moveDown();
                break;
        }

        if (moved) {
            this.addRandomTile();
            this.updateDisplay();
            this.checkGameState();
        }
    }

    moveLeft() {
        let moved = false;
        for (let row = 0; row < 4; row++) {
            const newRow = this.slideArray(this.grid[row]);
            if (!this.arraysEqual(this.grid[row], newRow)) {
                moved = true;
                this.grid[row] = newRow;
            }
        }
        return moved;
    }

    moveRight() {
        let moved = false;
        for (let row = 0; row < 4; row++) {
            const reversed = [...this.grid[row]].reverse();
            const newRow = this.slideArray(reversed).reverse();
            if (!this.arraysEqual(this.grid[row], newRow)) {
                moved = true;
                this.grid[row] = newRow;
            }
        }
        return moved;
    }

    moveUp() {
        let moved = false;
        for (let col = 0; col < 4; col++) {
            const column = [this.grid[0][col], this.grid[1][col], this.grid[2][col], this.grid[3][col]];
            const newColumn = this.slideArray(column);
            if (!this.arraysEqual(column, newColumn)) {
                moved = true;
                for (let row = 0; row < 4; row++) {
                    this.grid[row][col] = newColumn[row];
                }
            }
        }
        return moved;
    }

    moveDown() {
        let moved = false;
        for (let col = 0; col < 4; col++) {
            const column = [this.grid[0][col], this.grid[1][col], this.grid[2][col], this.grid[3][col]];
            const reversed = [...column].reverse();
            const newColumn = this.slideArray(reversed).reverse();
            if (!this.arraysEqual(column, newColumn)) {
                moved = true;
                for (let row = 0; row < 4; row++) {
                    this.grid[row][col] = newColumn[row];
                }
            }
        }
        return moved;
    }

    slideArray(arr) {
        const filtered = arr.filter(val => val !== 0);
        const missing = 4 - filtered.length;
        const zeros = Array(missing).fill(0);
        const newArray = filtered.concat(zeros);
        
        for (let i = 0; i < 3; i++) {
            if (newArray[i] !== 0 && newArray[i] === newArray[i + 1]) {
                newArray[i] *= 2;
                newArray[i + 1] = 0;
                this.score += newArray[i];
            }
        }
        
        const filtered2 = newArray.filter(val => val !== 0);
        const missing2 = 4 - filtered2.length;
        const zeros2 = Array(missing2).fill(0);
        return filtered2.concat(zeros2);
    }

    arraysEqual(a, b) {
        return JSON.stringify(a) === JSON.stringify(b);
    }

    addRandomTile() {
        const emptyCells = [];
        for (let row = 0; row < 4; row++) {
            for (let col = 0; col < 4; col++) {
                if (this.grid[row][col] === 0) {
                    emptyCells.push({row, col});
                }
            }
        }
        
        if (emptyCells.length > 0) {
            const randomCell = emptyCells[Math.floor(Math.random() * emptyCells.length)];
            this.grid[randomCell.row][randomCell.col] = Math.random() < 0.9 ? 2 : 4;
        }
    }

    updateDisplay() {
        const container = document.getElementById('tile-container');
        container.innerHTML = '';
        
        for (let row = 0; row < 4; row++) {
            for (let col = 0; col < 4; col++) {
                if (this.grid[row][col] !== 0) {
                    const tile = document.createElement('div');
                    tile.className = `tile tile-${this.grid[row][col]}`;
                    tile.textContent = this.grid[row][col];
                    
                    // Use CSS Grid positioning instead of absolute positioning
                    tile.style.gridColumn = `${col + 1}`;
                    tile.style.gridRow = `${row + 1}`;
                    
                    if (this.grid[row][col] > 2048) {
                        tile.className = 'tile tile-super';
                        tile.textContent = this.grid[row][col];
                    }
                    
                    container.appendChild(tile);
                }
            }
        }
    }

    updateScore() {
        document.getElementById('score').textContent = this.score;
        
        if (this.score > this.best) {
            this.best = this.score;
            localStorage.setItem('best2048', this.best);
        }
        
        document.getElementById('best').textContent = this.best;
    }

    checkGameState() {
        this.updateScore();
        
        // Check for 2048 tile (game won)
        if (!this.gameWon && !this.keepPlaying) {
            for (let row = 0; row < 4; row++) {
                for (let col = 0; col < 4; col++) {
                    if (this.grid[row][col] === 2048) {
                        this.gameWon = true;
                        this.showMessage('You Win!', 'game-won');
                        return;
                    }
                }
            }
        }
        
        // Check for game over
        if (this.isGameOver()) {
            this.gameOver = true;
            this.showMessage('Game Over!', 'game-over');
        }
    }

    isGameOver() {
        // Check for empty cells
        for (let row = 0; row < 4; row++) {
            for (let col = 0; col < 4; col++) {
                if (this.grid[row][col] === 0) {
                    return false;
                }
            }
        }
        
        // Check for possible merges
        for (let row = 0; row < 4; row++) {
            for (let col = 0; col < 4; col++) {
                const current = this.grid[row][col];
                if (
                    (row < 3 && current === this.grid[row + 1][col]) ||
                    (col < 3 && current === this.grid[row][col + 1])
                ) {
                    return false;
                }
            }
        }
        
        return true;
    }

    showMessage(text, className) {
        const messageElement = document.getElementById('game-message');
        messageElement.querySelector('p').textContent = text;
        messageElement.className = `game-message ${className}`;
        messageElement.style.display = 'block';
    }

    hideMessage() {
        const messageElement = document.getElementById('game-message');
        messageElement.style.display = 'none';
    }

    restart() {
        this.hideMessage();
        this.init();
    }

    keepPlayingGame() {
        this.hideMessage();
        this.keepPlaying = true;
    }
}

// Initialize the game when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new Game2048();
});
