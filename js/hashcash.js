const hashcash = {
  generate: function (stamp) {
    const [version, bits ] = stamp.split(':');
    return hashcash.solution(stamp, 0, bits);
  },

  solution: async function (stamp, count, bits) {
  const stamp_with_count = stamp + ':' + count;
    const digits = await hashcash.sha(stamp_with_count);
    if (hashcash.count_zeros(digits) >= bits) {
      return stamp_with_count;
    } else {
      return hashcash.solution(stamp, count+1, bits);
    }
  },

  digest_to_binary: function (digest) {
    return Array.from(new Uint8Array(digest))
      .map(b => b.toString(2).padStart(8,'0')).join('');
  },

  sha: function (string) {
    const encoder = new TextEncoder();
    const data = encoder.encode(string);
    return crypto.subtle.digest("SHA-1",data)
      .then(hashcash.digest_to_binary);
  },

  count_zeros: function (base2_string) {
    for(var i=0; i<base2_string.length; i++) {
      if (base2_string[i]=="1") { return i; }
    }
    return i;
  }
};
