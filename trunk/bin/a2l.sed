1i\
\\documentclass[CJK]{cctart}\\usepackage{times}\
\\let\\DQ=1\
\\def\\doublequote{\\ifx\\DQ1\\let\\DQ=2``\\else\\let\\DQ=1''\\fi}\
\\begin{document}

s/\\/\\textbackslash /g
s/ /\\ /g
s/{/\\{/g
s/}/\\}/g
s/\$/\\$/g
s/_/\\_/g
s/&/\\&/g
s/\#/\\#/g
s/%/\\%/g
s/\^/\\verb|^|/g
s/~/\\verb|~|/g
s/</\\verb|<|/g
s/>/\\verb|>|/g
s/\"/\\doublequote /g
a\


$a\
\\end{document}
