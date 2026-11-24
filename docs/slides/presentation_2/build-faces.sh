#!/bin/zsh
# slides WITH the The Office faces (for the talk, local only, git-ignored): -> coco-faces.pdf
cd "$(dirname "$0")"
for i in 1 2; do pdflatex -interaction=nonstopmode -jobname=coco-faces "\def\withfaces{1}\input{coco}" >/dev/null; done
grep -q "^!" coco-faces.log && grep "^!" coco-faces.log || echo "done: coco-faces.pdf"
