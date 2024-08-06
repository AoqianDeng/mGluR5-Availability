# -*- coding: utf-8 -*-
"""
Created on Tue Jan  9 10:12:02 2024

@author: DengAoQian
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# Load the data
file_path = 'F:\\PET_article\\percentage.xlsx'
data = pd.read_excel(file_path)

# Define the brain regions
brain_regions = ['dlPFC', 'vmPFC', 'OFC', 'caudate', 'hippocampus', 'amygdala']

# Set up the matplotlib figure
plt.figure(figsize=(16, 10))

# Create subplots for each brain region with custom styles
for i, region in enumerate(brain_regions, 1):
    plt.subplot(2, 3, i)
    sns.scatterplot(x=data[region], y=data['HAMD'], s=100)  # Increase size of scatter points
    plt.title(f'{region}', fontsize=18)
    plt.xlabel(f'{region} mGLUR5 availability change rate(%)', fontsize=14)
    plt.ylabel('HAMD score change rate(%)', fontsize=14)

    # Fit a linear regression line
    slope, intercept, r_value, p_value, std_err = stats.linregress(data[region].to_numpy(), data['HAMD'].to_numpy())
    line = slope * data[region].to_numpy() + intercept
    plt.plot(data[region].to_numpy(), line, color='red', linewidth=2)  # Make line visible but not too prominent

    # Annotate the plot with r and p values
    plt.annotate(f'r = {r_value:.3f}\np = {p_value:.3f}', xy=(0.05, 0.05), xycoords='axes fraction',
                 horizontalalignment='left', verticalalignment='bottom', fontsize=14, 
                 bbox=dict(boxstyle="round,pad=0.3", edgecolor='gray', facecolor='white'))

plt.tight_layout()

# Save the figure as PNG and PDF
plt.savefig('F:\\PET_article\\scatter_plots3.png', dpi=600)
plt.savefig('F:\\PET_article\\scatter_plots3.pdf', dpi=600)

plt.show()

