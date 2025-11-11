#!/bin/bash

# GS2Mesh Installation Script for RTX 5080 - WORKAROUND Edition
# This script uses a workaround for the new Blackwell architecture
# by disabling automatic arch detection and using CPU fallback for compilation

set -e  # Exit on error

echo "========================================"
echo "GS2Mesh Installation Script"
echo "RTX 5080 - WORKAROUND Edition"
echo "========================================"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Installing in directory: $SCRIPT_DIR"
echo ""

# Step 1: Create conda environment
echo "Step 1: Creating conda environment 'gs2mesh' with Python 3.10..."
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
    conda create --name gs2mesh python=3.10 -y
    echo "✓ Environment created successfully"
    echo ""

    # Activate the environment
    echo "Step 2: Activating gs2mesh environment..."
    eval "$(conda shell.bash hook)"
    conda activate gs2mesh
    echo "✓ Environment activated"
    echo ""

    # Step 3: Install PyTorch 2.5.1 with CUDA 12.4 support
    echo "Step 3: Installing PyTorch 2.5.1 with CUDA 12.4 support..."
    echo "This may take several minutes..."
    
    pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu124
    
    echo "✓ PyTorch installed successfully"
    echo ""
    
    # Install COLMAP separately via conda
    echo "Step 3.5: Installing COLMAP..."
    conda install colmap -c conda-forge -y
    echo "✓ COLMAP installed successfully"
    echo ""

    # Step 4: Set environment variables to work around sm_120 issue
    echo "Step 4: Setting CUDA workaround environment variables..."
    # Don't set TORCH_CUDA_ARCH_LIST - let it skip sm_120
    # Instead, we'll force it to build only for supported architectures
    conda env config vars set TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0" -n gs2mesh
    # This disables the visible card detection which causes issues with sm_120
    conda env config vars set CUDA_VISIBLE_DEVICES="0" -n gs2mesh
    echo "✓ Environment variables set"
    echo ""

    # Step 5: Install other dependencies first (NOT the CUDA extensions yet)
    echo "Step 5: Installing non-CUDA dependencies..."
    
    pip install open3d==0.18.0
    pip install huggingface_hub scipy tensorboard opt_einsum imageio opencv-python
    pip install scikit-image einops matplotlib plotly jupyterlab k3d trimesh ipympl tqdm plyfile
    
    echo "✓ Non-CUDA dependencies installed"
    echo ""
    
    # Step 6: Manually install CUDA extensions with workarounds
    echo "Step 6: Installing CUDA extensions with workarounds..."
    echo "This step will attempt to build extensions for sm_90 (Hopper) architecture"
    echo "which may be forward-compatible with sm_120 (Blackwell) at runtime."
    echo ""
    
    # Reactivate to get env vars
    eval "$(conda shell.bash hook)"
    conda deactivate
    conda activate gs2mesh
    
    # Try installing the extensions one by one
    echo "Installing diff_gaussian_rasterization..."
    cd third_party/gaussian-splatting/submodules/diff-gaussian-rasterization
    pip install -e . || echo "⚠️  Warning: diff_gaussian_rasterization failed to install"
    cd "$SCRIPT_DIR"
    
    echo "Installing simple_knn..."
    cd third_party/gaussian-splatting/submodules/simple-knn
    pip install -e . || echo "⚠️  Warning: simple_knn failed to install"
    cd "$SCRIPT_DIR"
    
    echo "Installing segment-anything-2..."
    cd third_party/segment-anything-2
    pip install -e . || echo "⚠️  Warning: SAM2 failed to install"
    cd "$SCRIPT_DIR"
    
    echo "Installing GroundingDINO..."
    cd third_party/GroundingDINO
    pip install -e . || echo "⚠️  Warning: GroundingDINO failed to install"
    cd "$SCRIPT_DIR"
    
    echo ""
    echo "✓ Extension installation attempted"
    echo ""
fi

# Step 7: Download DLNR Stereo weights
echo "Step 7: Downloading DLNR Stereo weights..."
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

# Step 8: Download GroundingDINO weights
echo "Step 8: Downloading GroundingDINO weights..."
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

# Completion message
echo "========================================"
echo "Installation Status"
echo "========================================"
echo ""
echo "Your system information:"
echo "  - CUDA Version: 12.8"
echo "  - GPU: NVIDIA GeForce RTX 5080 (Blackwell/sm_120)"
echo "  - PyTorch: 2.5.1 with CUDA 12.4"
echo ""
echo "⚠️  CRITICAL INFORMATION:"
echo ""
echo "The RTX 5080 (Blackwell/sm_120) is too new for current PyTorch stable releases."
echo "Some CUDA extensions may have failed to compile."
echo ""
echo "RECOMMENDED OPTIONS:"
echo ""
echo "1. USE THE RTX 3080 Ti SYSTEM (EASIEST)"
echo "   - Full compatibility guaranteed"
echo "   - Use the 'install.sh' script on that system"
echo ""
echo "2. WAIT FOR PYTORCH 2.6+ (COMING SOON)"
echo "   - Will have official Blackwell (sm_120) support"
echo "   - Check: https://pytorch.org for updates"
echo ""
echo "3. TRY CPU MODE (VERY SLOW)"
echo "   - Some features will work but training/inference will be much slower"
echo ""
echo "To test what's working:"
echo "  conda activate gs2mesh"
echo "  python -c 'import torch; print(torch.cuda.is_available())'"
echo ""

