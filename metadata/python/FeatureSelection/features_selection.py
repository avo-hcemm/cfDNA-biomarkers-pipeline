'''
Created on Jul 17, 2024

@author: avo
'''

import sys
import os
os.environ["SCIPY_ARRAY_API"] = "1"
# from pandas.tests.frame.test_validate import dataframe
original_stdout = sys.stdout

# Get the directory where the current script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
# Get the parent directory of the script directory (one level up)
parent_dir = os.path.dirname(script_dir)

# Add your module folders located under the parent directory to sys.path
sys.path.insert(0, os.path.join(parent_dir, 'Mylogging'))
sys.path.insert(0, os.path.join(parent_dir, 'StatisticalValidation'))

from collections import defaultdict
import pandas as pd
import numpy as np

from numpy import mean
from numpy import std

import mylogging
import math
from itertools import permutations

# Machine learning and statistical tools
from sklearn.feature_selection import RFE
from sklearn.model_selection import train_test_split
from collections import Counter
from imblearn.over_sampling import SMOTE
from sklearn.model_selection import RepeatedStratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import cross_val_score
from sklearn.metrics import accuracy_score

# Feature selection with embedded hyperparameter tuning
from shaphypetune import  BoostRFE
import xgboost as xgb

# MANOVA test and assumptions checking
#import pre_manova
#from statsmodels.multivariate.manova import MANOVA

#PERMANOVA
from skbio.stats.distance import DistanceMatrix, permanova, permdisp 
from scipy.spatial.distance import pdist, squareform, cdist

import warnings
warnings.filterwarnings('ignore', module = 'statsmodels')

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
"""## Statistical **parameters**"""

pValue = 0.05
test_statistic = "Wilks' lambda"

# Logging module name
name = "FeatureSelection"

def write_features_and_importances(filepath, selected_features, importances_dic, all_columns, modified_col_map, logger=None):
    """
    Writes selected features and their importances to file.
    Unselected features get 0.0 importance. Underscores in modified columns are replaced with dashes.

    Parameters:
    - filepath: output file path
    - selected_features: list of selected feature names
    - importances_dic: list of importances for selected features (same order)
    - all_columns: full list of features before selection
    - name_map: dictionary of column names where underscore was replaced
    - logger: optional logger for error/info messages
    """
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        # Pair features with their importances
        # feature_importance_pairs = [(feat, importances_dic[feat]) for feat in selected_features if importances_dic[feat] > 0.0]
        feature_importance_pairs = [(feat, importances_dic[feat]) for feat in selected_features]
    
        # Sort by importance (descending)
        feature_importance_pairs.sort(key=lambda x: x[1], reverse=True)
    
        # Unzip sorted features and importances
        sorted_features, sorted_importances = zip(*feature_importance_pairs)

        # Prepare feature names (with underscore fix if needed)
        features_line = ",".join(modified_col_map.get(feat, feat)
            for feat in sorted_features)

        # Full distribution of importances in the same order
        importances_line = ",".join(str(imp) for imp in sorted_importances)

        # Write to file
        with open(filepath, 'w') as f:
            f.write(features_line + "\n")
            f.write(importances_line + "\n")

        if logger:
            logger.info(f"{len(selected_features)} selected features saved to {filepath}")
            logger.debug(f"Saved features: {selected_features}")

    except Exception as e:
        if logger:
            logger.error("Failed to write selected features: " + str(e), exc_info=True)
        else:
            print("Error writing features:", e)
        sys.exit(3)

def detect_constant_groups(data_df, group_col, min_group_size=3, tol=1e-8):
    """
    Detect groups that are either:
      1. Feature-constant across all samples (variance < tol for all features)
      2. Too small to reliably compute PERMDISP/PERMANOVA (size < min_group_size)

    Parameters
    ----------
    data_df : pd.DataFrame
        Dataframe containing features and group labels.
    group_col : str
        Name of the column containing group labels.
    min_group_size : int, default=3
        Minimum number of samples required in a group.
    tol : float, default=1e-8
        Variance threshold below which a group is considered constant.

    Returns
    -------
    constant_groups : list of str
        List of group names that are constant or too small.
    """
    constant_groups = []

    for group, group_data in data_df.groupby(group_col):
        n_samples = len(group_data)
        print(f"\nChecking group '{group}' with {n_samples} samples")

        # Flag group if too small
        if n_samples < min_group_size:
            print(f" -> Group '{group}' has <{min_group_size} samples, marking as constant/small.")
            constant_groups.append(group)
            continue

        # Drop the group label column to analyze features only
        features = group_data.drop(columns=[group_col]).values

        # Compute variance per feature across samples in this group
        var_per_feature = np.var(features, axis=0)
        print(f" -> Variance per feature: {var_per_feature}")

        # Flag group if all features are constant within tolerance
        if np.all(var_per_feature < tol):
            print(f" -> Group '{group}' is feature-constant (all variances < {tol}).")
            constant_groups.append(group)

    return constant_groups

def add_noise_to_zeros(dm, epsilon=1e-8):
    arr = dm.data.copy()
    
    arr += np.random.normal(0, epsilon, arr.shape)
    
    arr = (arr + arr.T)/2 # enforce symmetry
    
    # Keep diagonal zero
    np.fill_diagonal(arr, 0)
    
    return DistanceMatrix(arr, ids=dm.ids)

def permutation_test_vs_constant(X, groups, constant_group, n_permutations=999, metric='euclidean', random_state=None):
    """
    Permutation test comparing average distance of non-constant groups to a fixed reference point (constant group centroid).
    
    Parameters:
    - X: DataFrame of selected features
    - groups: array-like of group labels (aligned with X)
    - constant_group: name of the constant group
    - n_permutations: number of permutations
    - metric: distance metric (default: Euclidean)
    - random_state: reproducibility seed

    Returns:
    - p_value: permutation-based p-value
    - observed_stat: observed average distance to the constant group centroid
    - permutation_distribution: array of permuted statistics
    """
    rng = np.random.default_rng(random_state)

    # Extract centroid of the constant group
    ref_point = X.loc[groups == constant_group].mean(axis=0).values.reshape(1, -1)

    # Compute distances from all samples to this reference point
    distances = cdist(X.values, ref_point, metric=metric).flatten()

    # Compute observed mean distance for non-constant groups
    non_const_groups = [g for g in np.unique(groups) if g != constant_group]
    observed_means = [distances[groups == g].mean() for g in non_const_groups]
    observed_stat = np.mean(observed_means)

    # Permutation test
    perm_stats = np.empty(n_permutations)
    for i in range(n_permutations):
        permuted = rng.permutation(groups)
        perm_means = [distances[permuted == g].mean() for g in non_const_groups]
        perm_stats[i] = np.mean(perm_means)

    # Compute p-value (upper tail)
    p_value = (np.sum(perm_stats >= observed_stat) + 1) / (n_permutations + 1)

    return p_value, observed_stat, perm_stats

def evaluate_model_performance(X_train, X_valid, y_train, y_valid, features=None):
    """
    Train and evaluate XGBoost classifier using given features.
    If features is None, use all features in X_train.
    Returns accuracy on validation set.
    """
    
    # Select features if specified
    if features is not None:
        X_train = X_train[features]
        X_valid = X_valid[features]
        
    num_classes = len(np.unique(y_train))
    if num_classes == 2:
        model = xgb.XGBClassifier(
            objective='binary:logistic',
            n_estimators=100,
            random_state=123,
            eval_metric=["error", "logloss"],
            early_stopping_rounds=4,
        )
    else:
        model = xgb.XGBClassifier(
            objective='multi:softprob',
            n_estimators=100,
            random_state=123,
            eval_metric=["merror", "mlogloss"],
            early_stopping_rounds=4,
            num_class=num_classes,
        )
    
    model.fit(X_train, y_train, eval_set=[(X_valid, y_valid)], verbose=0)
    y_pred = model.predict(X_valid)
    return accuracy_score(y_valid, y_pred)

def get_dynamic_xgb_params(n_samples, n_features, num_classes, seed=0):
    
    # ----- max_depth -----
    if n_samples < 5000:
        max_depth = 4
    elif n_samples < 50000:
        max_depth = 6
    else:
        max_depth = 8
    
    # ----- learning rate -----
    if n_samples < 5000:
        learning_rate = 0.05
    elif n_samples < 50000:
        learning_rate = 0.03
    else:
        learning_rate = 0.01
    
    # ----- n_estimators -----
    if n_samples < 5000:
        n_estimators = 300
    elif n_samples < 50000:
        n_estimators = 600
    else:
        n_estimators = 1200
    
    # ----- subsample -----
    subsample = 0.6 if n_samples < 5000 else 0.8
    
    # ----- colsample_bytree -----
    if n_features < 50:
        colsample_bytree = 0.9
    elif n_features < 500:
        colsample_bytree = 0.7
    else:
        colsample_bytree = 0.5
    
    # ----- regularization -----
    if n_samples < 5000:
        min_child_weight = 1
        gamma = 0.1
    elif n_samples < 50000:
        min_child_weight = 3
        gamma = 0.3
    else:
        min_child_weight = 6
        gamma = 1.0
    
    params = dict(
        objective = 'multi:softprob' if num_classes > 2 else 'binary:logistic',
        n_estimators = n_estimators,
        learning_rate = learning_rate,
        max_depth = max_depth,
        subsample = subsample,
        colsample_bytree = colsample_bytree,
        min_child_weight = min_child_weight,
        gamma = gamma,
        reg_lambda = 1.5,
        reg_alpha = 0.5,
        random_state = seed,
        eval_metric = ['mlogloss','merror'] if num_classes > 2 else ['logloss','error'],
        num_class = num_classes if num_classes > 2 else None,
        early_stopping_rounds = 20
    )
    
    return params


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
def if_stat_signif_features(dataframe,output_file,number,logger_functions,logger_stats):
    """
    Selects a minimum number of features using XGBoost-based RFE and 
    evaluates their statistical significance with PERMANOVA.

    Returns the PERMANOVA p-value and the list of selected features.
    """
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # Create a working copy of the dataframe
    X = dataframe.copy()
    
    # Encode diagnostic status as numeric values
    X['Diagnostic_status'] = X['Diagnostic_status'].astype("category").cat.codes
    y = X['Diagnostic_status']
    X.drop(['Diagnostic_status'], axis=1, inplace=True)
    
    # Rows, columns, number of classes of initial dataset
    rows, columns = X.shape
    num_classes = len(np.unique(y))
    print(f"Number of classes detected before XGBoost training: {num_classes}")
    if num_classes < 1:
        raise ValueError(f"Error: number of classes is less than 1: {num_classes}")

    # Exit if fewer than 2 classes
    if num_classes < 2:
        raise ValueError(f"Error: insufficient number of classes for training (found {num_classes}). At least 2 classes are required.")
    
    # Get feature column names
    list_columns = X.columns.values.tolist()
    # Split data: 70% training, 30% validation
    X_train_tmp,X_valid,y_train_tmp,y_valid = train_test_split(X, y,test_size=0.3,random_state=0, stratify=y)

    class_counts = Counter(y_train_tmp)
    minority_count = min(class_counts.values())
    minority_ratio = minority_count / max(class_counts.values())

    # Apply SMOTE only if the dataset is unbalanced
    if  minority_ratio < 0.4:
        # Not enough samples for SMOTE, use RandomOverSampler instead
        from imblearn.over_sampling import RandomOverSampler
        ros = RandomOverSampler(random_state=42)
        X_train, y_train = ros.fit_resample(X_train_tmp, y_train_tmp)
        print("Minority class too small, used RandomOverSampler:", Counter(y_train))
    elif minority_ratio < 0.5:  # threshold, e.g., minority <50% of majority
        k_neighbors = max(1, minority_count - 1)
        smote = SMOTE(random_state=42, k_neighbors=k_neighbors)
        X_train, y_train = smote.fit_resample(X_train_tmp, y_train_tmp)
        print("After SMOTE resampling:", Counter(y_train))
    else:
        # If balanced enough, the analysis moves on
        print("Dataset is balanced, SMOTE not applied")

    # Train XGBoost classifier with BoostRFE
    # Print info to debug XGBoost parameter error
    logger_functions.info("The selected model is: BoostRFE")
    print("The selected model is: BoostRFE")
    
    # Repetitions for stability
    n_runs = 5  # number of repetitions
    n_splits = 2
    n_repeats = 3
    
    all_rankings = defaultdict(list)
    all_importances = defaultdict(list)
    
    # Define cross-validation scheme: 2 splits, repeated 3 times, stratified by class
    cv = RepeatedStratifiedKFold(n_splits=n_splits, n_repeats=n_repeats, random_state=123456)
        

    for seed in range(n_runs):
        
        for size in [4, 5, 6, 7]:
            X_train,X_valid,y_train,y_valid = train_test_split(X, y,test_size=size/10,random_state=0, stratify=y)
            
            # print(f"x shape: {X.shape}")
            # print(f"x_train shape: {X_train.shape}")
    
            # Update XGBoost random_state
            params = get_dynamic_xgb_params(
            n_samples=X_train.shape[0],
            n_features=X_train.shape[1],
            num_classes=num_classes,
            seed=seed
            )
        
            print("max_depth",params["max_depth"])
            print("learning_rate",params["learning_rate"])
            print("n_estimators",params["n_estimators"])
            
            xg_cl = xgb.XGBClassifier(**params)

            # Limit number of features to available features
            number = min(number, X_train.shape[1])
            print(f"number of minimum features to train the model before rfe:{number}")
    
            #Apply recursive feature elimination
            rfe = BoostRFE(estimator = xg_cl, min_features_to_select = number, step = 1)
            # Fit model using BoostRFE
            try:
                rfe.fit(X_train, y_train, eval_set=[(X_valid, y_valid)], verbose=0)
            except xgb.core.XGBoostError as e:
                logger_functions.exception("XGBoost fitting failed")
                raise
    
            # Collect feature rankings and importances
            for feat, rank in zip(X_train.columns, rfe.ranking_):
                all_rankings[feat].append(rank)
            fitted_estimator = rfe.estimator_
            # try:
            #     print("Best iteration:", fitted_estimator.best_iteration)
            # except Exception as e:
            #     print("Error accessing best_iteration:", e)
            #
            # try:
            #     print("Number of trees:", fitted_estimator.get_booster().num_boosted_rounds())
            # except Exception as e:
            #     print("Error accessing booster:", e)
            #
            # print("Selected features:", rfe.support_)
            # print("Features importances:", fitted_estimator.feature_importances_)
            
            for feat, imp in zip(X_train.columns[rfe.support_], fitted_estimator.feature_importances_):
                all_importances[feat].append(imp)
                
            print(f"Unique ranks for seed {seed}:", np.unique(rfe.ranking_))


    # Aggregate rankings and importances across runs
    final_rankings = {feat: np.mean(ranks) if ranks else 0.0
                        for feat, ranks in all_rankings.items()}
    final_importances = {feat: np.mean(imps) if imps else 0.0
      for feat, imps in all_importances.items()}

    # Sort features by aggregated final ranking
    sorted_features = sorted(final_rankings.items(), key=lambda x: x[1])
    # print("Final feature rankings:")
    # for feat, avg_rank in sorted_features:
    #     print(f"{feat}: {avg_rank:.2f}")

    # Store selected features with ranks=1
    list_selectedFeat = [feat for feat, rank in sorted_features if rank == 1]

    # Print selected features
    print(f"Number of selected features: {len(list_selectedFeat)}")
    # print("Selected features:")
    # for feat in list_selectedFeat:
    #     print(f"selectedFeat: {feat}")

    # dictionary of important features based on the aggregate final ranking scores during iterative XGBoost run
    importances_dic = {feat: final_importances[feat] for feat in list_selectedFeat }
    # print("Final feature importance scores:")
    # for feat, avg_imp in importances_dic.items():
    #     print(f"{feat}: {avg_imp:.2f}")
    
   # Validate that features were selected
    if not list_selectedFeat:
        logger_functions.error("No features were selected by RFE. PERMANOVA cannot be performed.")
        raise ValueError("No features were selected by RFE. PERMANOVA requires at least one feature.")

    # Prepare selected features
    X_selected = dataframe.loc[:, list_selectedFeat]
    
    # Get group labels from original dataframe, also converted to str for index alignment
    groups = dataframe.loc[X_selected.index, 'Diagnostic_status'].astype(str)

    # Now convert index to string for distance matrix
    X_selected.index = X_selected.index.astype(str)
    ids = X_selected.index.tolist()
    groups.index = groups.index.astype(str)  # Ensure index type matches ids

    # Extract groups with exact alignment to X_selected
    aligned_df = X_selected.copy()
    aligned_df['Diagnostic_status'] = groups

    constant_groups = detect_constant_groups(aligned_df, 'Diagnostic_status')
    print("Constant or too-small groups: ",constant_groups)
    variable_groups = [g for g in groups.unique() if g not in constant_groups ]

    # Minimal data check
    if X_selected.shape[0] < 3 or len(groups.unique()) < 2:
        logger_stats.error("Too few samples or diagnostic groups to run PERMANOVA.")
        return 1.0, [], {}

    # NaN check
    if X_selected.isnull().values.any():
        logger_stats.error("NaN values detected in selected features. Cannot compute distance matrix.")
        return 1.0, [], {}

    try:
        # Compute distance matrix (Euclidean by default, but can be 'braycurtis', 'jaccard', etc.)
        distance_matrix = squareform(pdist(X_selected, metric='euclidean'))
        # dm = DistanceMatrix(distance_matrix, ids=[str(i) for i in ids])
        dm = DistanceMatrix(distance_matrix, ids=ids)

        # Align indices safely
        X_selected = X_selected.reindex(dm.ids)
        groups = groups.reindex(dm.ids)
        
        dm = add_noise_to_zeros(dm)

        # If constant group(s) exist, run special test
        if constant_groups:
            reference_group = constant_groups[0]
            print(f"Constant or small groups detected: {constant_groups}. Using distance-to-fixed-point permutation test with {reference_group}")
            logger_stats.info(f"Detected constant/small group(s): {constant_groups}. Using distance-to-fixed-point permutation test.")
            
            p_value, observed_stat, perm_dist = permutation_test_vs_constant(
                X_selected,
                groups,
                reference_group,
                n_permutations=999,
                metric='euclidean'
            )
            
            logger_stats.info(
            f"Permutation test vs constant group ({reference_group}): "
            f"observed_stat={observed_stat:.4f}, p={p_value:.4f}"
            )
            test_result = {
                "method": "perm_vs_constant",
                "statistic": observed_stat,
                "p_value": p_value
            }

        else:
            # Check for Homogeneity of group dispersions
            print("no constant groups. Running PERMDISP + PERMANOVA")
            disp_result = permdisp(dm, groups)
            logger_stats.info(f"PERMDISP result: {disp_result}")

            if disp_result['p-value'] < 0.05:
                logger_stats.warning("Warning: group dispersions differ significantly (PERMDISP p < 0.05). PERMANOVA results may be confounded by dispersion differences.")

            # Run PERMANOVA
            print("Run PERMANOVA")
            permanova_result = permanova(dm, grouping=groups, permutations=999)
            p_value = permanova_result['p-value']
            logger_stats.info(f"PERMANOVA result: pseudo-F={permanova_result['test statistic']:.4f}, p={p_value:.4f}")
            test_result = {
                "method": "permanova",
                "statistic": permanova_result['test statistic'],
                "p_value": p_value
            }

        return test_result['p_value'], list_selectedFeat, importances_dic


    except Exception as e:
        logger_stats.exception(f"PERMANOVA or distance matrix computation failed: {e}")
        return 1.0, [], {} # Default to non-significant


    
def calc_stat_sign_feat(dataframe, outputfile, size, name_map,logger_functions, logger_write,logger_stats):
    """
    Iteratively performs feature selection and PERMANOVA analysis
    to identify statistically significant features. It evaluates the accuracy 
    of the trained model on these features.

    Parameters:
    - dataframe: input data with diagnostic labels
    - outputfile: path to save selected features
    - size: initial minimum number of features to select (used as 
            min_features_to_select in BoostRFE)
    - name_map: feature names that were modified (underscores to dashes)

    Returns:
    - Final number of selected features that were statistically significant
    """
    logger_functions.info("Inside the " + name + " module.")
    
    times = 0
    significant = False
    selected_features = []
    
    while not significant:
        try:
            # Run the feature selection + PERMANOVA test, get p-value and features
            times += 1
            p_value, selected_features, importances_dic = if_stat_signif_features(dataframe,outputfile,size,logger_functions,logger_stats)
            # for feat in selected_features:
                # print(f"selected feature: {feat}")
            print(f"PERMANOVA results: p_value {p_value}")
            print(f"importance_values_list {importances_dic}")
            logger_functions.info(f"Attempt #{times}: running feature selection + PERMANOVA for size = {size}")
            logger_functions.info(f"this is the probability {p_value} for minimum feature size: {size}")
        except Exception as e:
            # Log and exit on error
            logger_functions.error("An exception occurred: %s", e, exc_info=True)
            sys.exit(3)
    
        if p_value is not None and not math.isnan(p_value) and p_value < pValue: # if p_value is a valid number and statistically significant
            significant = True
            # print(f"significant {significant}")
            # for feat in selected_features:
            #     print(f"selected feature: {feat}")
            # print(f"Statistically significant features (p = {p_value:.4g}): {len(selected_features)} features")
            logger_functions.info(f"Statistically significant features (p = {p_value:.4g}): {len(selected_features)} features")
            logger_functions.info("Selected features: " + str(selected_features))
            
            logger_write.info("Inside the " + name + " module.")
            
            # Performance evaluation
            X = dataframe.copy()
            X['Diagnostic_status'] = X['Diagnostic_status'].astype("category").cat.codes
            y = X['Diagnostic_status']
            X.drop(['Diagnostic_status'], axis=1, inplace=True)
            X_train, X_valid, y_train, y_valid = train_test_split(X, y, train_size=0.7, test_size=0.3, random_state=0)
            # Evaluate performance BEFORE feature selection (all features)
            acc_before = evaluate_model_performance(X_train, X_valid, y_train, y_valid, features=None)
            logger_write.info(f"XGBoost accuracy before feature selection: {acc_before:.4f}")

            # Evaluate performance AFTER feature selection (selected features)
            acc_after = evaluate_model_performance(X_train, X_valid, y_train, y_valid, features=selected_features)
            logger_write.info(f"XGBoost accuracy after feature selection: {acc_after:.4f}")
            
            write_features_and_importances(
                filepath=outputfile,
                selected_features=selected_features,
                importances_dic=importances_dic,
                all_columns=X_train.columns,
                modified_col_map=name_map,
                logger=logger_write
            )
    
        else:
            if p_value is None or math.isnan(p_value):# if p_value is not a valid number 
                logger_functions.warning(f"Received NaN p-value — treating as non-significant for size: {size}")
            else:# if p_value is a valid number but not statistically significant
                print(f"significant {significant}")
                logger_functions.warning(f"Not statistically significant result for PERMANOVA with {len(selected_features)} features (p = {p_value:.4g})")
            # the minimum number of statistically significant features is reduced
            if size > 10:
                size -= 1
            else:
                logger_functions.warning("Minimum size reached with no statistically significant result")
                finaldf = dataframe.copy()
                finaldf.drop(['Diagnostic_status'], axis=1, inplace=True)
                selected_features = finaldf.columns.values.tolist()
                importances_dic = {feat: 0.0 for feat in selected_features}
                all_columns = selected_features.copy()
                
                write_features_and_importances(
                    filepath=outputfile,
                    selected_features=selected_features,
                    importances_dic=importances_dic,  # all zeroes if fallback
                    all_columns=selected_features,
                    modified_col_map=name_map,
                    logger=logger_write
                )

                break

    return size

