# Set up directories and environment variables
export SUBJECTS_DIR=/data/qianbao
export PET_DIR=$SUBJECTS_DIR/pet
export MRI_DIR=$SUBJECTS_DIR/mri
export OUTPUT_DIR=$SUBJECTS_DIR/output
export MNI_TEMPLATE=$SUBJECTS_DIR/mni/MNI152_T1_1mm.nii

# Register PET to MRI
for subject in $(ls $PET_DIR); do
    mkdir -p $OUTPUT_DIR/$subject
    flirt -in $PET_DIR/$subject/pet.nii -ref $MRI_DIR/$subject/t1.nii -out $OUTPUT_DIR/$subject/pet2t1.nii -omat $OUTPUT_DIR/$subject/pet2t1.mat
done

# Use FreeSurfer to segment T1 images and obtain cerebellum mask
for subject in $(ls $MRI_DIR); do
    recon-all -i $MRI_DIR/$subject/t1.nii -subjid $subject -sd $OUTPUT_DIR -all
done

# Extract cerebellum mask and compute cerebellar mean signal
for subject in $(ls $MRI_DIR); do
    # Extract cerebellum mask including white and gray matter
    mri_binarize --i $OUTPUT_DIR/$subject/mri/aseg.mgz --match 7 8 46 47 --o $OUTPUT_DIR/$subject/cerebellum_mask.nii.gz

    # Apply cerebellum mask to registered PET image
    fslmaths $OUTPUT_DIR/$subject/pet2t1.nii -mas $OUTPUT_DIR/$subject/cerebellum_mask.nii.gz $OUTPUT_DIR/$subject/cerebellum_pet.nii.gz

    # Compute cerebellar mean signal
    fslstats $OUTPUT_DIR/$subject/cerebellum_pet.nii.gz -M > $OUTPUT_DIR/$subject/cerebellum_mean_signal.txt
done

# Use ANTS to normalize T1 images to MNI152 template
for subject in $(ls $MRI_DIR); do
    antsRegistrationSyNQuick.sh -d 3 -f $MNI_TEMPLATE -m $MRI_DIR/$subject/t1.nii -o $OUTPUT_DIR/$subject/ants_
done

# Normalize PET images to MNI space
for subject in $(ls $OUTPUT_DIR); do
    antsApplyTransforms -d 3 -i $OUTPUT_DIR/$subject/pet2t1.nii -r $MNI_TEMPLATE -o $OUTPUT_DIR/$subject/pet2mni.nii -t $OUTPUT_DIR/$subject/ants_1Warp.nii.gz -t $OUTPUT_DIR/$subject/ants_0GenericAffine.mat
done

# Calculate non-displaceable binding potential (BPND)
for subject in $(ls $OUTPUT_DIR); do
    cerebellum_mean_signal=$(cat $OUTPUT_DIR/$subject/cerebellum_mean_signal.txt)
    fslmaths $OUTPUT_DIR/$subject/pet2mni.nii -sub $cerebellum_mean_signal -div $cerebellum_mean_signal $OUTPUT_DIR/$subject/BPND.nii
done

# Group comparison analysis
randomise -i $OUTPUT_DIR/BPND -o $OUTPUT_DIR/stats -d design.mat -t design.con -e design.grp --T2 -n 5000

