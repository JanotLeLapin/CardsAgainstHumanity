const values = 'azertyuiopqsdfghjklmwxcvbn1234567890'

export const roomName = () => {
  let res = '';
  for (let i = 0; i < 4; i++) res += values[Math.floor(Math.random() * values.length)];
  return res;
}

