#!/bin/bash

# GS2Mesh Installation Script for RTX 5080 (Blackwell Architecture)
# For CUDA 12.8+ / RTX 5080
# Uses PyTorch NIGHTLY with potential support for sm_120 (Blackwell)

set -e  # Exit on error

echo "========================================"
echo "GS2Mesh Installation Script"
echo "RTX 5080 (Blackwell) - NIGHTLY Edition"
echo "========================================"
echo ""
echo "WARNING: This uses PyTorch nightly builds which may be unstable"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Installing in directory: $SCRIPT_DIR"
echo ""

# Step 1: Create conda environment
echo "Step 1: Creating conda environment 'gs2mesh' with Python 3.11..."
echo "Note: Using Python 3.11 for best compatibility with nightly PyTorch"
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
    conda create --name gs2mesh python=3.11 -y
    echo "✓ Environment created successfully"
    echo ""

    # Activate the environment
    echo "Step 2: Activating gs2mesh environment..."
    eval "$(conda shell.bash hook)"
    conda activate gs2mesh
    echo "✓ Environment activated"
    echo ""

    # Step 3: Install PyTorch nightly with CUDA 12.4+ support
    echo "Step 3: Installing PyTorch NIGHTLY with CUDA 12.4 support..."
    echo "This may take several minutes..."
    
    # Install PyTorch nightly which should have better Blackwell support
    pip3 install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu124
    
    echo "✓ PyTorch nightly installed successfully"
    echo ""
    
    # Install COLMAP separately via conda
    echo "Step 3.5: Installing COLMAP..."
    conda install colmap -c conda-forge -y
    echo "✓ COLMAP installed successfully"
    echo ""

    # Step 4: Try to set environment variable for newer architectures
    echo "Step 4: Setting CUDA architecture flags..."
    # Try sm_90 (Hopper) as fallback since sm_120 isn't officially supported yet
    export TORCH_CUDA_ARCH_LIST="9.0"
    conda env config vars set TORCH_CUDA_ARCH_LIST="9.0" -n gs2mesh
    echo "✓ CUDA architecture flags set to sm_90 (Hopper compatibility mode)"
    echo "  Note: Compiling for sm_90; may work with sm_120 via forward compatibility"
    echo ""

    # Step 5: Install additional dependencies from requirements.txt
    echo "Step 5: Installing additional dependencies from requirements.txt..."
    
    # Install Open3D with a version compatible with Python 3.11
    pip install open3d==0.18.0
    
    # Install other dependencies (excluding open3d since we already installed it)
    grep -v "open3d" requirements.txt > /tmp/requirements_temp.txt
    pip install -r /tmp/requirements_temp.txt
    rm /tmp/requirements_temp.txt
    
    echo "✓ Additional dependencies installed successfully"
    echo ""
fi

# Step 6: Download DLNR Stereo weights
echo "Step 6: Downloading DLNR Stereo weights..."
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

# Step 7: Download GroundingDINO weights
echo "Step 7: Downloading GroundingDINO weights (for automatic masking)..."
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

# Step 8: Optional - Download SAM2 weights (optional, as they auto-download)
echo "Step 8: SAM2 weights (optional)..."
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
echo "  - CUDA Version: 12.8"
echo "  - GPU: NVIDIA GeForce RTX 5080 (Blackwell/sm_120)"
echo "  - PyTorch: Nightly with CUDA 12.4 support"
echo "  - Compiled for: sm_90 (Hopper) - may work on sm_120 via forward compatibility"
echo ""
echo "IMPORTANT: You must reactivate the environment for settings to take effect:"
echo "  conda deactivate"
echo "  conda activate gs2mesh"
echo ""
echo "To test the installation, run:"
echo "  python -c 'import torch; print(f\"PyTorch: {torch.__version__}\"); print(f\"CUDA Available: {torch.cuda.is_available()}\"); print(f\"CUDA Version: {torch.version.cuda}\"); print(f\"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}\")'"
echo ""
echo "⚠️  IMPORTANT NOTES FOR RTX 5080:"
echo "  1. CUDA extensions will compile on first use (takes ~5-10 minutes)"
echo "  2. May see warnings about sm_120 not being fully supported - this is expected"
echo "  3. If compilation fails, the GPU may be too new for current PyTorch"
echo "  4. Consider waiting for official PyTorch support for Blackwell (sm_120)"
echo ""
echo "For usage examples, check the README.md or run:"
echo "  - Custom data: python run_single.py --colmap_name <data_name> --video_extension <extension>"
echo ""
echo "Alternative: Consider using the RTX 3080 Ti system for now, as it has full support."
echo ""

