
1i\    .processor HD6303

# Strings
s/fcc/DC/g

# Bytes
s/fcb/DC/g

# Double bytes
s/fdb/DC.W/g

# Uninitialsed data labels
s/rmb/DS.B/g

# Instructions
s/lda\sa/LDAA/g
s/lda\sb/LDAB/g
s/sta\sa/STAA/g
s/sta\s\sa/STAA/g
s/sta\sb/STAB/g
s/sta\s\sb/STAB/g
s/tst\sa/TSTA/g
s/tst\sb/TSTB/g

# DASM can't handle '*/' when it's in a string
s/\*\/MO/\/\/MO/g

