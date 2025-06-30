#!/bin/bash
set -e

curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh

curr_dir=$(pwd)
python_version=$(/opt/conda/bin/python --version | awk '{print $2}' | cut -d'.' -f1-2)
mkdir /opt/base-uv
cd /opt/base-uv
uv init --python ">=${python_version},<3.13"
uv venv
source .venv/bin/activate

uv add \
  torch \
  torchvision \
  torchaudio \
  --default-index https://download.pytorch.org/whl/cpu

# Install core data science packages first
# Issue with scipy 1.16.0 and various packages
uv add \
  pyrsm \
  "scipy==1.15.3" \
  pandas \
  sqlalchemy \
  psycopg2 \
  ipython-sql \
  scikit-learn \
  mlxtend \
  xgboost \
  lightgbm \
  statsmodels \
  linearmodels \
  --default-index https://pypi.org/simple/

# Install web scraping and NLP packages
uv add \
 spacy \
  nltk \
  textblob \
  transformers[torch] \
  huggingface_hub \
  gensim \
  vadersentiment \
  --default-index https://pypi.org/simple/

# Install visualization and utility packages
uv add \
  graphviz \
  seaborn \
  plotnine \
  plotly \
  networkx \
  matplotlib \
  --default-index https://pypi.org/simple/

# Install development and notebook packages
uv add \
  IPython \
  jupytext \
  isort \
  xlrd \
  openpyxl \
  xlsx2csv \
  jupysql \
  markdown \
  radian \
  shiny \
  shinywidgets \
  --default-index https://pypi.org/simple/

# Install database and file handling packages
uv add \
  duckdb \
  duckdb-engine \
  fastexcel \
  polars \
  connectorx \
  --default-index https://pypi.org/simple/

# Install math and simulation packages
uv add \
  sympy \
  simpy \
  lime \
  shap \
  --default-index https://pypi.org/simple/

# Install big data packages
uv add \
  findspark \
  pyspark \
  --default-index https://pypi.org/simple/

# Install causal inference packages
# requires tensorflowl  econml \
uv add \
  dowhy \
  causalml[torch] \
  --default-index https://pypi.org/simple/

# Install environment packages
uv add \
  python-dotenv \
  --default-index https://pypi.org/simple/

# Install bash_kernel separately to avoid dependency conflicts
uv add bash_kernel awscli \
  --default-index https://pypi.org/simple/

uv run python -m bash_kernel.install

chown -R jovyan /opt/base-uv
cd $curr_dir
