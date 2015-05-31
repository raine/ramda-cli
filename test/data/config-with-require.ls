require! 'ramda': {to-upper}

export shout = to-upper >> (+ '!')
