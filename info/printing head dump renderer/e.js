const fs = require('fs');
// const }{} = require('canvas');

const folderPath = process.argv[2];
const filePath = folderPath + '/' + 'digital.csv';
const file = fs.readFileSync(filePath) + '';


const { createCanvas } = require('canvas')
const canvas = createCanvas(600, 10000)
const ctx = canvas.getContext('2d')

ctx.fillStyle = "rgba(255,255,255,255)";
ctx.fillRect(0, 0, 600, 10000);

const fileLines = file.split('\n').filter(Boolean)
fileLines.shift()

const zeroTimeLength = '0.000000000'.length;
const getTimeLength = (line) => (line[1] === '.') ? zeroTimeLength : (line[2] === '.') ? zeroTimeLength + 1 : zeroTimeLength + 2

const getChannelInLine = (line, channelIndex) => {
  try {
    const timeLength = getTimeLength(line)
    return { data: line[timeLength + 1 + (channelIndex * 2)] === '0' ? 0 : 1, time: line.substring(0, timeLength) }
  } catch (e) { debugger }
}

// const clockIndex = 2;
// const dataIndex = 1;
// const latchIndex = 3;
const clockIndex = 3;
const dataIndex = 2;
const latchIndex = 1;

let lastClock = 0;
let lastData = 0;
let lastLatch = getChannelInLine(fileLines[0], latchIndex).data
let lastLatchTime = '0.000000000';

const rows = [[]]


let columnIndex = 0
const latchDates = []
fileLines.forEach(line => {
  const clock = getChannelInLine(line, clockIndex).data
  const data = getChannelInLine(line, dataIndex).data
  const { data: latch, time: latchTime } = getChannelInLine(line, latchIndex)
  // debugger
  if (clock !== lastClock) {
    if (clock === 1) {
      // console.log(clock)
      rows[columnIndex].push(data)
    }
    lastClock = clock;
  }
  if (latch !== lastLatch) {
    if (latch === 1) {
      columnIndex += 1
      rows[columnIndex] = []
      // latchDates.push(lastLatchTime - latchTime);
      if ((latchTime - lastLatchTime) > 0.0005 && (latchTime - lastLatchTime) < 1) { //usual values  //0.000013833000000129658 //0.001001875000000041
        rows[columnIndex] = 'latch'
        columnIndex += 1
        rows[columnIndex] = []
      }
    }
    lastLatchTime = latchTime;
    lastLatch = latch;
  }
})
// debugger
let removedWhite = 0
for (var n = rows.length; n--;) {
  // console.log(n)
  // console.log()
  if (!Array.isArray(rows[n]) || rows[n].every(e => !e)) {
    if (Array.isArray(rows[n])) removedWhite += 1
    rows.pop()
  }
  else break
}
console.log('removed ' + removedWhite + ' white')

// console.log(rows[0].length / 576)
rows.forEach((row, rowIndex) => {
  if (row === 'latch') return;
  row.forEach((column, columnIndex) => {
    ctx.fillStyle = column ? "rgba(0,0,0,255)" : "rgba(255,255,255,255)";
    ctx.fillRect(columnIndex, rowIndex, 1, 1);
  }
  )
})
console.log(rows.filter(e => Array.isArray(e)).length)
debugger

fs.writeFileSync(folderPath + '/' + 'canvas.png', canvas.toBuffer())