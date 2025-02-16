#!/bin/bash

set -e

mamba install --quiet --yes -c conda-forge \
  scipy=${SCIPY_VERSION} \
  pandas \
  sqlalchemy \
  psycopg2 \
  ipython-sql \
  beautifulsoup4 \
  scikit-learn \
  mlxtend \
  xgboost \
  lightgbm \
  graphviz \
  lime \
  shap \
  spacy \
  nltk \
  pydotplus \
  networkx \
  seaborn \
  plotnine \
  selenium \
  sqlalchemy \
  pyLDAvis \
  python-dotenv \
  statsmodels \
  linearmodels \
  IPython \
  jupytext \
  black \
  isort \
  streamlit \
  xlrd \
  openpyxl \
  python-duckdb \
  duckdb-engine \
  sympy \
  simpy \
  awscli \
  findspark \
  plotly \
  markdown \
  bash_kernel \
  && python -m bash_kernel.install

# Install Python packages
mamba install --quiet --yes -c pytorch \
  pytorch \
  torchvision

pip install --no-cache-dir --root-user-action=ignore \
  radian \
  fastexcel \
  polars \
  xlsx2csv \
  jupysql \
  pyrsm \
  textblob \
  transformers \
  gensim \
  vadersentiment \
  gradio \
  shinywidgets \
  dowhy \
  econml \
  uv

# causalml does not support python 3.12 yet
# https://github.com/uber/causalml/issues/813
# causalml[torch] \

# causing issues
# alpaca-trade-api \

# updating conda to the latest version
mamba update -n base -c conda-forge conda

# Clean up
mamba clean --all -f -y
