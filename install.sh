#!/bin/bash

# GS2Mesh Installation Script
# For CUDA 13.0 / RTX 3080 Ti
# This script installs gs2mesh with PyTorch compatible with CUDA 12.1+

set -e  # Exit on error

echo "========================================"
echo "GS2Mesh Installation Script"
echo "========================================"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Installing in directory: $SCRIPT_DIR"
echo ""

# Step 1: Create conda environment
echo "Step 1: Creating conda environment 'gs2mesh' with Python 3.8..."
if conda env list | grep -q "^gs2mesh "; then
    echo "Warning: Environment 'gs2mesh' already exists."
    read -p "Do you want to remove and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        conda remove -n gs2mesh --all -y
    else
        echo "Skipping environment creation. Activating existing environment..."
        eval "$(conda shell.bash hook)"
        conda activate gs2mesh
        echo "Environment activated. Continuing with remaining steps..."
        SKIP_CONDA_INSTALL=true
    fi
fi

if [ -z "$SKIP_CONDA_INSTALL" ]; then
    conda create --name gs2mesh python=3.8 -y
    echo "✓ Environment created successfully"
    echo ""

    # Activate the environment
    echo "Step 2: Activating gs2mesh environment..."
    eval "$(conda shell.bash hook)"
    conda activate gs2mesh
    echo "✓ Environment activated"
    echo ""

    # Step 3: Install PyTorch with CUDA 12.1 support
    echo "Step 3: Installing PyTorch 2.3.1 with CUDA 12.1 support..."
    echo "This may take several minutes..."
    conda install pytorch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 pytorch-cuda=12.1 colmap -c pytorch -c nvidia -c conda-forge -y
    echo "✓ PyTorch installed successfully"
    echo ""

    # Step 4: Install additional dependencies from requirements.txt
    echo "Step 4: Installing additional dependencies from requirements.txt..."
    pip install -r requirements.txt
    echo "✓ Additional dependencies installed successfully"
    echo ""
fi

# Step 5: Download DLNR Stereo weights
echo "Step 5: Downloading DLNR Stereo weights..."
mkdir -p third_party/DLNR/pretrained
cd third_party/DLNR/pretrained

if [ ! -f "DLNR_Middlebury.pth" ]; then
    echo "Downloading DLNR_Middlebury.pth..."
    wget https://github.com/David-Zhao-1997/High-frequency-Stereo-Matching-Network/releases/download/v1.0.0/DLNR_Middlebury.pth
    echo "✓ DLNR_Middlebury.pth downloaded"
else
    echo "✓ DLNR_Middlebury.pth already exists, skipping..."
fi

if [ ! -f "DLNR_SceneFlow.pth" ]; then
    echo "Downloading DLNR_SceneFlow.pth..."
    wget https://github.com/David-Zhao-1997/High-frequency-Stereo-Matching-Network/releases/download/v1.0.0/DLNR_SceneFlow.pth
    echo "✓ DLNR_SceneFlow.pth downloaded"
else
    echo "✓ DLNR_SceneFlow.pth already exists, skipping..."
fi

cd "$SCRIPT_DIR"
echo ""

# Step 6: Download GroundingDINO weights
echo "Step 6: Downloading GroundingDINO weights (for automatic masking)..."
mkdir -p third_party/GroundingDINO/weights
cd third_party/GroundingDINO/weights

if [ ! -f "groundingdino_swint_ogc.pth" ]; then
    echo "Downloading groundingdino_swint_ogc.pth..."
    wget https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth
    echo "✓ GroundingDINO weights downloaded"
else
    echo "✓ groundingdino_swint_ogc.pth already exists, skipping..."
fi

cd "$SCRIPT_DIR"
echo ""

# Step 7: Optional - Download SAM2 weights (optional, as they auto-download)
echo "Step 7: SAM2 weights (optional)..."
echo "Note: SAM2 weights will auto-download via Huggingface when needed."
read -p "Do you want to download SAM2 weights locally? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p third_party/segment-anything-2/checkpoints
    cd third_party/segment-anything-2/checkpoints
    if [ ! -f "sam2_hiera_large.pt" ]; then
        echo "Downloading sam2_hiera_large.pt..."
        wget https://dl.fbaipublicfiles.com/segment_anything_2/072824/sam2_hiera_large.pt
        echo "✓ SAM2 weights downloaded"
    else
        echo "✓ sam2_hiera_large.pt already exists, skipping..."
    fi
    cd "$SCRIPT_DIR"
else
    echo "Skipping SAM2 local weights download."
fi
echo ""

# Completion message
echo "========================================"
echo "✓ Installation Complete!"
echo "========================================"
echo ""
echo "Your system information:"
echo "  - CUDA Version: 13.0"
echo "  - GPU: NVIDIA GeForce RTX 3080 Ti (12GB)"
echo "  - PyTorch: 2.3.1 with CUDA 12.1 support"
echo ""
echo "To activate the environment, run:"
echo "  conda activate gs2mesh"
echo ""
echo "To test the installation, you can run:"
echo "  python -c 'import torch; print(f\"PyTorch: {torch.__version__}\"); print(f\"CUDA Available: {torch.cuda.is_available()}\"); print(f\"CUDA Version: {torch.version.cuda}\")'"
echo ""
echo "For usage examples, check the README.md or run:"
echo "  - DTU dataset: python run_and_evaluate_dtu.py"
echo "  - Custom data: python run_single.py --colmap_name <data_name> --video_extension <extension>"
echo ""
echo "Happy 3D reconstructing!"
echo ""

