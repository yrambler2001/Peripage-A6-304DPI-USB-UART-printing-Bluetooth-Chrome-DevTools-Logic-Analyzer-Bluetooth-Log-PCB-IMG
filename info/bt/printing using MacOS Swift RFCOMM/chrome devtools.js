// socket = websocket connect ...

socket.send(
  JSON.stringify({
    type: 'dataToPrinter',
    data: JSON.stringify([
      { type: 'send', data: '10ff3011' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '10ff20f1' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '10ff20f2' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '10ff50f1' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '000000000000000000000000' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '10fffe01' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '000000000000000000000000' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '10ff100000' },
      { type: 'wait', data: '100' },
      { type: 'send', data: '1d76300030005c01' },
      { type: 'wait', data: '100' },
      ...((array, chunk_size) =>
        Array(Math.ceil(array.length / chunk_size))
          .fill(undefined)
          .map((_, index) => index * chunk_size)
          .map((begin) => array.slice(begin, begin + chunk_size)))(img.split(''), 99999999)
        .map((e) => e.join(''))
        .map((e) => [{ type: 'send', data: e+'1b4a6010fffe45' }, { type: 'wait', data: '20' }]).flat(),
    ]),
      
  }),
);
